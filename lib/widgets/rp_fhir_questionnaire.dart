import 'dart:convert';

import 'package:fhir/r4/r4.dart';
import 'package:research_package/model.dart';

class RPFhirQuestionnaire {
  String _getText(QuestionnaireItem item) {
    return item.textElement?.extension_[0].valueString ?? item.text;
  }

  late final Questionnaire _questionnaire;

  RPAnswerFormat _buildChoiceAnswers(QuestionnaireItem element) {
    var choices = <RPChoice>[];

    if (element.answerValueSet != null) {
      final key =
          element.answerValueSet.value.substring(1); // Strip off leading '#'
      var i = 0;
      (_questionnaire.contained
                  .firstWhere((element) => (element.id.toString() == key))
              as ValueSet)
          .compose
          .include
          .first
          .concept
          .forEach((element) {
        choices.add(RPChoice.withParams(element.display, i++));
      });
    } else {
      var i =
          0; // TODO: Don't forget to put the real values back into the response...
      element.answerOption?.forEach((choice) {
        choices.add(RPChoice.withParams(choice.valueCoding.display, i++));
      });
    }

    return RPChoiceAnswerFormat.withParams(
        ChoiceAnswerStyle.SingleChoice, choices);
  }

  List<RPQuestionStep> _buildQuestionSteps(QuestionnaireItem item, int level) {
    final steps = <RPQuestionStep>[];

    final optional = !(item.required_?.value ?? true);

    switch (item.type) {
      case QuestionnaireItemType.choice:
        steps.add(RPQuestionStep.withAnswerFormat(
            item.linkId, _getText(item), _buildChoiceAnswers(item),
            optional: optional));
        break;
      case QuestionnaireItemType.string:
        steps.add(RPQuestionStep.withAnswerFormat(
            item.linkId,
            _getText(item),
            RPChoiceAnswerFormat.withParams(ChoiceAnswerStyle.SingleChoice,
                [RPChoice.withParams(_getText(item), 0, true)]),
            optional: optional));
        break;
      case QuestionnaireItemType.decimal:
        steps.add(RPQuestionStep.withAnswerFormat(item.linkId, _getText(item),
            RPIntegerAnswerFormat.withParams(0, 999999),
            optional:
                optional)); // TODO: surveys are using "Decimal" when they are clearly expecting integers.
        break;
      default:
        print('Unsupported question item type: ${item.type.toString()}');
    }
    return steps;
  }

  List<RPStep> _buildSteps(QuestionnaireItem item, int level) {
    var steps = <RPStep>[];

    switch (item.type) {
      case QuestionnaireItemType.group:
        steps.add(RPInstructionStep(
          identifier: item.linkId,
          detailText:
              'Please fill out this survey.\n\nIn this survey the questions will come after each other in a given order. You still have the chance to skip some of them, though.',
          title: item.code?.first?.display,
        )..text = item.text);

        item.item.forEach((groupItem) {
          steps.addAll(_buildSteps(groupItem, level + 1));
        });
        break;
      case QuestionnaireItemType.choice:
      case QuestionnaireItemType.string:
      case QuestionnaireItemType.decimal:
        steps.addAll(_buildQuestionSteps(item, level));
        break;
      default:
        print('Unsupported item type: ${item.type.toString()}');
    }
    return steps;
  }

  List<RPStep> fhirQuestionnaire(String jsonFhirQuestionnaire) {
    _questionnaire = Questionnaire.fromJson(json.decode(jsonFhirQuestionnaire));

    final toplevelSteps = <RPStep>[];
    _questionnaire.item.forEach((item) {
      toplevelSteps.addAll(_buildSteps(item, 0));
    });

    return toplevelSteps;
  }

  RPCompletionStep completionStep() {
    return RPCompletionStep('completionID')
      ..title = 'Finished'
      ..text = 'Thank you for filling out the survey!';
  }

  RPOrderedTask surveyTask(String jsonFhirQuestionnaire) {
    return RPOrderedTask(
      'surveyTaskID',
      [...fhirQuestionnaire(jsonFhirQuestionnaire), completionStep()],
    );
  }
}
