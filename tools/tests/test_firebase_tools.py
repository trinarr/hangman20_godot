import io
import json
from pathlib import Path
import sys
import tempfile
import unittest
import xml.etree.ElementTree as ET
import zipfile

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / "tools"))
from prepare_firebase_android import prepare


class FirebaseBuildChecks(unittest.TestCase):
    def test_preparation_is_reproducible_and_rejects_wrong_package(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            (root / "export_presets.cfg").write_text('[preset.0.options]\npackage/unique_name="com.example.game"\n', encoding="utf-8")
            config = root / "config.json"
            config.write_text(json.dumps({"client": [{"client_info": {"android_client_info": {"package_name": "wrong"}}}]}), encoding="utf-8")
            template = root / "template"
            template.mkdir()
            settings = template / "settings.gradle"
            build = template / "build.gradle"
            settings.write_text('pluginManagement {\n    plugins {\n    }\n}\n', encoding="utf-8")
            build.write_text('plugins {\n}\n', encoding="utf-8")
            with self.assertRaises(ValueError):
                prepare(root, config, template)
            self.assertNotIn("google-services", build.read_text())
            config.write_text(config.read_text().replace('wrong', 'com.example.game'), encoding="utf-8")
            with self.assertRaises(ValueError):
                prepare(root, config, template, check=True)
            prepare(root, config, template)
            snapshot = build.read_bytes(), settings.read_bytes()
            prepare(root, config, template)
            prepare(root, config, template, check=True)
            self.assertEqual(snapshot, (build.read_bytes(), settings.read_bytes()))
            self.assertEqual((template / "google-services.json").read_bytes(), config.read_bytes())

    def test_shipped_bridges_have_analytics_apis_and_safe_startup(self):
        for variant in ("debug", "release"):
            for addon, tokens in [
                ("HangmanFirebase", [b"setCollectionEnabled", b"logEvent"]),
                ("GodotAndroidYandexAds", [b"_on_ad_impression", b"showInterstitialForRequest",
                                          b"_on_rewarded_shown_for_request",
                                          b"_on_interstitial_shown_for_request", b"_on_interstitial_failed_for_request",
                                          b"_on_interstitial_closed_for_request"]),
            ]:
                with self.subTest(variant=variant, addon=addon):
                    with zipfile.ZipFile(ROOT / f"addons/{addon}/bin/{variant}/{addon}-{variant}.aar") as archive:
                        with zipfile.ZipFile(io.BytesIO(archive.read("classes.jar"))) as classes:
                            data = b"".join(classes.read(name) for name in classes.namelist() if name.endswith(".class"))
                        for token in tokens:
                            self.assertIn(token, data)
                        if addon == "HangmanFirebase":
                            manifest = archive.read("AndroidManifest.xml").decode("utf-8")
                            self.assertIn('tools:node="remove"', manifest)
                            android = "{http://schemas.android.com/apk/res/android}"
                            self.assertEqual(ET.fromstring(manifest).find("application").get(android + "name"),
                                             "com.trinarr.analytics.AnalyticsApplication")
                            self.assertIn(b"com/trinarr/analytics/AnalyticsApplication", data)
                            values = {item.get(android + "name"): item.get(android + "value")
                                      for item in ET.fromstring(manifest).findall("./application/meta-data")}
                            for name in ("firebase_analytics_collection_enabled", "google_analytics_adid_collection_enabled",
                                         "google_analytics_default_allow_ad_storage", "google_analytics_default_allow_ad_user_data",
                                         "google_analytics_default_allow_ad_personalization"):
                                self.assertEqual(values[name], "false")


if __name__ == "__main__":
    unittest.main()
