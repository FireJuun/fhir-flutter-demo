import 'dart:convert';

import 'package:fhir/r4.dart';
import 'package:fhir_flutter_demo/widgets/rp_fhir_questionnaire.dart';
import 'package:flutter/material.dart';
import 'package:research_package/research_package.dart';

class SurveyPage extends StatelessWidget {
  final instrument;
  final RPFhirQuestionnaire _questionnaire;

  SurveyPage(this.instrument)
      : _questionnaire = RPFhirQuestionnaire(instrument);

  String _encode(Object object) =>
      const JsonEncoder.withIndent(' ').convert(object);

  void _resultCallback(RPTaskResult result) {
    // Do anything with the result
    print(_encode(result));
    print(_questionnaire.fhirQuestionnaireResponse(
        result, QuestionnaireResponseStatus.completed));
  }

  void _cancelledCallback(RPTaskResult result) {
    // Do anything with the result
    print('Cancelled!');
    print(_encode(result));
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
        data: ThemeData(
          primaryColor: Colors.white,
          accentColor: Colors.orange,
          backgroundColor: Colors.white,
          dividerColor: Colors.grey,
          textTheme: Typography.blackMountainView,
        ),
        child: RPUITask(
          task: _questionnaire.surveyTask(),
          onSubmit: (result) {
            _resultCallback(result);
          },
          // No onCancel
          // If there's no onCancel provided the survey just quits
          onCancel: (result) {
            _cancelledCallback(result);
          },
        ));
  }
}
