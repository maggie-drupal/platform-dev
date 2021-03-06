@api @poetry @theme_wip
Feature: Fast track

  Background:
    Given these modules are enabled
      | modules                     |
      | ne_dgt_rules                |
      | ne_tmgmt_dgt_ftt_translator |
    And the following languages are available:
      | languages |
      | en        |
      | fr        |
      | es        |
    And the following Poetry settings:
    """
      address: {{ wsdl }}
      method: requestService
    """
    And I request to change the variable "ne_dgt_rules_translator" to "dgt_ftt"

  @ec_europa_theme
  Scenario: Fast track workflow.
    Given I update the "dgt_ftt" translator settings with the following values:
    """
      settings:
        dgt_counter: '40012'
        dgt_code: WEB
        callback_username: poetry
        callback_password: pass
        dgt_ftt_username: user
        dgt_ftt_password: pass
        dgt_ftt_workflow_code: STS
      organization:
        responsible: DIGIT
        author: IE/CE/DIGIT
        requester: IE/CE/DIGIT
      contacts:
        author: john_smith
        secretary: john_smith
        contact: john_smith
        responsible: john_smith
      feedback_contacts:
        email_to: john.smith@example.com
        email_cc: john.smith@example.com
    """
    And Poetry will return the following "response.status" message response:
    """
    identifier:
      code: WEB
      year: 2017
      number: 40012
      version: 0
      part: 0
      product: EDT
    status:
      -
        type: request
        code: '0'
        date: 06/10/2017
        time: 02:41:53
        message: OK
    """
    And I have the following rule:
    """
    {
      "rules_dgt_ftt_review" : {
        "LABEL" : "DGT FTT Review",
        "PLUGIN" : "reaction rule",
        "OWNER" : "rules",
        "REQUIRES" : [ "ne_dgt_rules", "rules", "workbench_moderation" ],
        "ON" : { "workbench_moderation_after_moderation_transition" : [] },
        "IF" : [
          { "comparison_of_moderation_states_after_transition" : {
              "previous_state_source" : [ "previous-state" ],
              "previous_state_value" : "draft",
              "new_state_source" : [ "new-state" ],
              "new_state_value" : "needs_review"
            }
          }
        ],
        "DO" : [
          { "ne_dgt_rules_ftt_node_send_review_request" : {
              "USING" : { "node" : [ "node" ] ,
                "delay" : "2017-12-01 15:00:00"
              },
              "PROVIDE" : {
                "tmgmt_job" : { "tmgmt_job" : "Translation Job" },
                "dgt_service_response" : { "dgt_service_response" : "DGT Service response" },
                "dgt_service_response_status" : { "dgt_service_response_status" : "DGT Service Response - Response status" },
                "dgt_service_demand_status" : { "dgt_service_demand_status" : "DGT Service Response - Demand status" }
              }
            }
          },
          { "drupal_message" : { "message" : [ "dgt-service-response-status:message" ] } },
          { "drupal_message" : { "message" : [ "dgt-service-demand-status:message" ] } },
          { "drupal_message" : { "message" : [ "dgt-service-response:raw-xml" ] } }
        ]
      }
    }
    """
    And I have the following rule:
    """
    {
      "rules_dgt_ftt_translations" : {
        "LABEL" : "DGT FTT Translations",
        "PLUGIN" : "reaction rule",
        "OWNER" : "rules",
        "REQUIRES" : [ "ne_dgt_rules", "rules", "workbench_moderation" ],
        "ON" : { "workbench_moderation_after_moderation_transition" : [] },
        "IF" : [
          { "comparison_of_moderation_states_after_transition" : {
              "previous_state_source" : [ "previous-state" ],
              "previous_state_value" : "needs_review",
              "new_state_source" : [ "new-state" ],
              "new_state_value" : "validated"
            }
          }
        ],
        "DO" : [
          { "ne_dgt_rules_ftt_node_send_translation_request" : {
              "USING" : { "node" : [ "node" ],
               "delay" : "2017-12-01 15:00:00",
               "dgt_ftt_workflow_code" : "STS"
              },
              "PROVIDE" : {
                "tmgmt_job" : { "tmgmt_job" : "Translation Job" },
                "dgt_service_response" : { "dgt_service_response" : "DGT Service response" },
                "dgt_service_response_status" : { "dgt_service_response_status" : "DGT Service Response - Response status" },
                "dgt_service_demand_status" : { "dgt_service_demand_status" : "DGT Service Response - Demand status" }
              }
            }
          },
          { "drupal_message" : { "message" : [ "dgt-service-response-status:message" ] } },
          { "drupal_message" : { "message" : [ "dgt-service-demand-status:message" ] } },
          { "drupal_message" : { "message" : [ "dgt-service-response:raw-xml" ] } }
        ]
      }
    }
    """
    And "page" content:
      | language | title     |
      | en       | Test page |
    And I am logged in as a user with the "administrator" role
    And I visit the "page" content with title "Test page"
    Then I should see "Revision state: Draft"
    When I select "Needs Review" from "state"
    And I press "Apply"
    Then I should see "Revision state: Needs Review"
    And Poetry service received request should contain the following text:
      | <produit>EDT</produit>                                        |
      | <titre>Test page</titre>                                      |
      | <organisationResponsable>DIGIT</organisationResponsable>      |
      | <organisationAuteur>IE/CE/DIGIT</organisationAuteur>          |
      | <serviceDemandeur>IE/CE/DIGIT</serviceDemandeur>          |
      | <applicationReference>FPFIS</applicationReference>            |
      | <delai>01/12/2017</delai>                                     |
      | <attributionsDelai>01/12/2017</attributionsDelai>             |
    When I select "Validated" from "state"
    And I press "Apply"
    Then I should see "Revision state: Validated"
    And Poetry service received request should contain the following text:
      | <produit>TRA</produit>                                        |
      | <titre>Test page</titre>                                      |
      | <organisationResponsable>DIGIT</organisationResponsable>      |
      | <organisationAuteur>IE/CE/DIGIT</organisationAuteur>          |
      | <serviceDemandeur>IE/CE/DIGIT</serviceDemandeur>          |
      | <applicationReference>FPFIS</applicationReference>            |
      | <delai>01/12/2017</delai>                                     |
      | <attributionsDelai>01/12/2017</attributionsDelai>             |

  Scenario: Optional action parameters.
    Given I update the "dgt_ftt" translator settings with the following values:
    """
      settings:
        dgt_counter: '40013'
        dgt_code: WEB
        callback_username: poetry
        callback_password: pass
        dgt_ftt_username: user
        dgt_ftt_password: pass
        dgt_ftt_workflow_code: STS
      organization:
        responsible: DIGIT
        author: IE/CE/DIGIT
        requester: IE/CE/DIGIT
      contacts:
        author: john_smith
        secretary: john_smith
        contact: john_smith
        responsible: john_smith
      feedback_contacts:
        email_to: john.smith@example.com
        email_cc: john.smith@example.com
    """
    And Poetry will return the following "response.status" message response:
    """
    identifier:
      code: CUSTOM
      year: 2017
      number: 40013
      version: 0
      part: 0
      product: EDT
    status:
      -
        type: request
        code: '0'
        date: 06/10/2017
        time: 02:41:53
        message: OK
    """
    And I have the following rule:
    """
    {
      "rules_dgt_ftt_review" : {
        "LABEL" : "DGT FTT Review",
        "PLUGIN" : "reaction rule",
        "OWNER" : "rules",
        "REQUIRES" : [ "ne_dgt_rules", "rules", "workbench_moderation" ],
        "ON" : { "workbench_moderation_after_moderation_transition" : [] },
        "IF" : [
          { "comparison_of_moderation_states_after_transition" : {
              "previous_state_source" : [ "previous-state" ],
              "previous_state_value" : "draft",
              "new_state_source" : [ "new-state" ],
              "new_state_value" : "needs_review"
            }
          }
        ],
        "DO" : [
          { "ne_dgt_rules_ftt_node_send_review_request" : {
              "USING" : { "node" : [ "node" ] ,
                "delay" : "2017-12-01 15:00:00",
                "code" : "CUSTOM",
                "org_responsible" : "DIGIT_REVIEW",
                "org_dg_author" : "IE/CE/DIGIT/REVIEW",
                "org_requester" : "IE/CE/DIGIT/REVIEW",
                "dgt_ftt_workflow_code" : "STS"
              },
              "PROVIDE" : {
                "tmgmt_job" : { "tmgmt_job" : "Translation Job" },
                "dgt_service_response" : { "dgt_service_response" : "DGT Service response" },
                "dgt_service_response_status" : { "dgt_service_response_status" : "DGT Service Response - Response status" },
                "dgt_service_demand_status" : { "dgt_service_demand_status" : "DGT Service Response - Demand status" }
              }
            }
          },
          { "drupal_message" : { "message" : [ "dgt-service-response-status:message" ] } },
          { "drupal_message" : { "message" : [ "dgt-service-demand-status:message" ] } },
          { "drupal_message" : { "message" : [ "dgt-service-response:raw-xml" ] } }
        ]
      }
    }
    """
    And I have the following rule:
    """
    {
      "rules_dgt_ftt_translations" : {
        "LABEL" : "DGT FTT Translations",
        "PLUGIN" : "reaction rule",
        "OWNER" : "rules",
        "REQUIRES" : [ "ne_dgt_rules", "rules", "workbench_moderation" ],
        "ON" : { "workbench_moderation_after_moderation_transition" : [] },
        "IF" : [
          { "comparison_of_moderation_states_after_transition" : {
              "previous_state_source" : [ "previous-state" ],
              "previous_state_value" : "needs_review",
              "new_state_source" : [ "new-state" ],
              "new_state_value" : "validated"
            }
          }
        ],
        "DO" : [
          { "ne_dgt_rules_ftt_node_send_translation_request" : {
              "USING" : { "node" : [ "node" ],
                "delay" : "2017-12-01 15:00:00",
                "code" : "CUSTOM",
                "org_responsible" : "DIGIT_TRANSLATION",
                "org_dg_author" : "IE/CE/DIGIT/TRANSLATION",
                "org_requester" : "IE/CE/DIGIT/TRANSLATION",
                "dgt_ftt_workflow_code" : "STS"
              },
              "PROVIDE" : {
                "tmgmt_job" : { "tmgmt_job" : "Translation Job" },
                "dgt_service_response" : { "dgt_service_response" : "DGT Service response" },
                "dgt_service_response_status" : { "dgt_service_response_status" : "DGT Service Response - Response status" },
                "dgt_service_demand_status" : { "dgt_service_demand_status" : "DGT Service Response - Demand status" }
              }
            }
          },
          { "drupal_message" : { "message" : [ "dgt-service-response-status:message" ] } },
          { "drupal_message" : { "message" : [ "dgt-service-demand-status:message" ] } },
          { "drupal_message" : { "message" : [ "dgt-service-response:raw-xml" ] } }
        ]
      }
    }
    """
    And "page" content:
      | language | title     |
      | en       | Test page |
    And I am logged in as a user with the "administrator" role
    When I visit the "page" content with title "Test page"
    Then I should see "Revision state: Draft"
    When I select "Needs Review" from "state"
    And I press "Apply"
    Then I should see "Revision state: Needs Review"
    And Poetry service received request should contain the following text:
      | <codeDemandeur>CUSTOM</codeDemandeur>                           |
      | <organisationResponsable>DIGIT_REVIEW</organisationResponsable> |
      | <organisationAuteur>IE/CE/DIGIT/REVIEW</organisationAuteur>     |
      | <serviceDemandeur>IE/CE/DIGIT/REVIEW</serviceDemandeur>     |
      | <workflowCode>STS</workflowCode>                                |
      | <delai>01/12/2017</delai>                                       |
      | <attributionsDelai>01/12/2017</attributionsDelai>               |
    When I select "Validated" from "state"
    And I press "Apply"
    Then I should see "Revision state: Validated"
    And Poetry service received request should contain the following text:
      | <codeDemandeur>CUSTOM</codeDemandeur>                        |
      | <organisationResponsable>DIGIT_TRANSLATION</organisationResponsable> |
      | <organisationAuteur>IE/CE/DIGIT/TRANSLATION</organisationAuteur>     |
      | <serviceDemandeur>IE/CE/DIGIT/TRANSLATION</serviceDemandeur>     |
      | <workflowCode>STS</workflowCode>                                     |
      | <delai>01/12/2017</delai>                                            |
      | <attributionsDelai>01/12/2017</attributionsDelai>                    |

  Scenario: When we configure the Fast Track translator contacts with uppercase and it's changed to lowercase
    Given I am logged in as a user with the "administrator" role
    And The module is enabled
      | modules                  |
      | ne_tmgmt_dgt_ftt_translator |
    When I am on "admin/config/regional/tmgmt_translator/manage/dgt_ftt_en"
    And I fill in "Counter" with "UPPERCASE"
    And I fill in "Requester code" with "UPPERCASE"
    And I fill in "Callback User" with "UPPERCASE"
    And I fill in "Callback Password" with "UPPERCASE"
    And I fill in "DGT FTT - username" with "UPPERCASE"
    And I fill in "DGT FTT - password" with "UPPERCASE"
    And I fill in "DGT FTT - workflow code" with "UPPERCASE"
    And I fill in "Responsible" with "UPPERCASE"
    And I fill in "DG Author" with "UPPERCASE"
    And I fill in "edit-settings-organization-requester" with "UPPERCASE"
    And I fill in "edit-settings-contacts-author" with "UPPERCASE"
    And I fill in "edit-settings-contacts-secretary" with "UPPERCASE"
    And I fill in "edit-settings-contacts-contact" with "UPPERCASE"
    And I fill in "edit-settings-contacts-responsible" with "UPPERCASE"
    And I fill in "Email to" with "UPPERCASE@example.com"
    And I fill in "Email CC" with "UPPERCASE@example.com"
    And I press "Save translator"
    Then I should see the success message "The configuration options have been saved."
    And I am on "admin/config/regional/tmgmt_translator/manage/dgt_ftt_en"
    Then The field "edit-settings-contacts-author" should containt "uppercase"
    And The field "edit-settings-contacts-secretary" should containt "uppercase"
    And The field "edit-settings-contacts-contact" should containt "uppercase"
    And The field "edit-settings-contacts-responsible" should containt "uppercase"
