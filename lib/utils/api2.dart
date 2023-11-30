import 'package:uno/uno.dart';

const String serviceUrl =
    "https://dhruva-api.bhashini.gov.in/services/inference/pipeline";
const String userId = "0fabeaae7e3d4a4684e36e35f3f9b667";
const String ulcaApiKey = "241a2dd58f-4ca2-4239-b6ce-ec64434c32e2";
const String inferenceApiKey =
    "noFk6yLYZoqHeitd-Nwmohu9Qb85Ok717_3Ace44a2wXawhefuS1BX9m7W2dtKEi";

Future<String> translate(
    String text, String sourceLang, String targetLang) async {
  final Uno uno = Uno();

  Map computePayload = {
    "pipelineTasks": [
      {
        "taskType": "translation",
        "config": {
          "language": {
            "sourceLanguage": sourceLang,
            "targetLanguage": targetLang
          }
        }
      }
    ],
    "inputData": {
      "input": [
        {"source": text}
      ]
    }
  };
  Map<String, String> computeHeaders = {
    "userID": userId,
    "ulcaApiKey": ulcaApiKey,
    "Authorization": inferenceApiKey
  };

  Response value =
      await uno.post(serviceUrl, data: computePayload, headers: computeHeaders);

  return value.data["pipelineResponse"][0]["output"][0]["target"];
}
