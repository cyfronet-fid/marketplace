# Jira integration

JIRA integration requires two side communication - from marketplace
to JIRA via JIRA's API, and from JIRA
to marketplace via JIRA's webhooks.

## Overview

JIRA integration require configuring mapping of several key properties.
This can be done via ENV variables
(described later on). JIRA instance itself should have
workflow and custom fields which corresponds to what
application itself expects (more in _JIRA instance requirements_),
at the end to make marketplace respond to changes
in JIRA webhook should be added to JIRA instance.

## How to? Instructions for admins

Here is a step by step tutorial which will teach you how to
connect marketplace to JIRA, and how to check whether
the integration works on the most rudimentary level.

### JIRA instance

JIRA instance does not require much additional configuration,
apart from configuring webhook, but it must
fulfill certain requirements described below.

Additionally new service user must be added to JIRA and have following priviledges:

- View issues & comments
- Add issue
- Add comment
- Update issue
- (optional) delete issue
- (optional) delete comment

Marketplace will perform all of it's operation as this user,
it's credentials will have to be provided to
the marketplace instance.

#### JIRA instance requirements

JIRA should fulfill following _workflow_ and _custom fields_ requirements

##### Workflow requirements

**TODO** - copy from documentation

##### Custom Fields requirements

**TODO** - copy from documentation

#### Configuring webhook

Providing that all requirements are fulfilled webhook should be configured as follows

Webhook url must be as follows
`<MP HOSTNAME e.g. http://localhost:5000>/api/webhooks/jira?issue_id=${issue.id}&secret=<app_secret>`.
`app_secret` should be the same as the one defined
in `jira.yml` - `webhook_secret` or in `MP_JIRA_WEBHOOK_SECRET`
environmental variable.
JQL for querying should be: `project = <PROJECT_KEY>`
All notifications for issues and comments should be enabled.

We will check validity of the webhook later, after configuring marketplace variables.

### Marketplace application instance

There is quite a few ENV variables which has to be provided
to application to make it work with JIRA, fortunately there
is a rake task to make your life easier.

#### Credentials

As a starter you should configure JIRA credentials:

- `MP_JIRA_USERNAME` - username of the service user
  as which application is accessing JIRA
- `MP_JIRA_PASSWORD` - password of the service user
  as which application is accessing JIRA
- `MP_JIRA_PROJECT` - project key in which marketplace will create / update issues
- `MP_JIRA_URL` - url to jira instance, (host and port, without part after `/`)
- `MP_JIRA_CONTEXT_PATH` - part of the url after first `/`

So if JIRA url is: `https://my.jira.net:8080/jira` then
`MP_JIRA_URL` will be `https://my.jira.net:8080` and
`MP_JIRA_CONTEXT_PATH` will be `/jira`. If there is no part
after `/` then `MP_JIRA_CONTEXT_PATH` should be left undefined

After setting these variables you should run following command:

```shell
rails jira:check
```

This rake task is your best friend when integrating with JIRA,
it will perform all sanity tests, and provide you with
guidance how to set up some more obscure variables.

After calling `jira:check` you should see something similar to this:

```raw
Checking JIRA instance on https://my.jira.net:8080
Checking connection... OK
Checking issue type presence... FAIL
  - ERROR: It seems that ticket with id 3 does not exist,
    make sure to add existing issue type into configuration
AVAILABLE ISSUE TYPES:
  - Task [id: 10100]
  - Sub-task [id: 10101]
  - Request for Change [id: 10302]
  - Improvement Suggestion  [id: 10205]
  - Service order [id: 10204]
  - Community requirement [id: 10300]
  - IS incident [id: 10400]
Checking project existence... OK
Trying to manipulate issue...
  - create issue... FAIL
    - ERROR: Could not create issue in project: EOSCSOSTAGING and issuetype: 3
  - check workflow transitions... FAIL
    - ERROR: Could not transition from 'TODO' to 'DONE' state,
      this will affect open access services
  - update issue... FAIL
    - ERROR: Could not update issue description
  - add comment to issue... FAIL
    - ERROR: Could not post comment
  - delete issue... FAIL
    - ERROR: Could not delete issue, reason: 405:
Checking workflow...
  - todo [id: 1]... OK
  - in_progress [id: 2]... FAIL
    - ERROR: STATUS WITH ID: 2 DOES NOT EXIST IN JIRA
  - waiting_for_response [id: 3]... OK
  - done [id: 4]... FAIL
    - ERROR: STATUS WITH ID: 4 DOES NOT EXIST IN JIRA
  - rejected [id: 5]... OK
Checking custom fields mappings... FAIL
  - ERROR: CUSTOM FIELD mapping have some problems
    - Order reference: ✕
    - CI-Name: ✕
    - CI-Surname: ✕
    - CI-Email: ✕
    - CI-DisplayName: ✕
    - CI-EOSC-UniqueID: ✕
    - CI-Institution: ✕
    - CI-Department: ✕
    - CI-DepartmentalWebPage: ✕
    - CI-SupervisorName: ✕
    - CI-SupervisorProfile: ✕
    - CP-CustomerTypology: ✕
    - CP-ReasonForAccess: ✕
    - CP-ScientificDiscipline: ✕
    - SO-1: ✕
SUGGESTED MAPPINGS ...
```

This means that marketplace could connect to jira,
but everything else is not configured yet. If the output says it
could not connect make sure that you configured user,
password, project, and urls correctly.

`jira:check` is providing you most of the information
needed for configuring JIRA integration.

#### Issue type

First let's start with setting up issue types.
As every JIRA instance can have different IDs for issue types they
must be provided manually in the configuration.
Marketplace required you to select 1 issue type which will be
used for creating issues, it shows you all available issue types:

```raw
AVAILABLE ISSUE TYPES:
  - Task [id: 10100]
  - Sub-task [id: 10101]
  - Request for Change [id: 10302]
  - Improvement Suggestion  [id: 10205]
  - Service order [id: 10204]
  - Community requirement [id: 10300]
  - IS incident [id: 10400]
```

Get id of the issue type which should be chosen and assign it to ENV variable `MP_JIRA_ISSUE_TYPE_ID`
In this case we would choose **Service Order [id: 10204]** so: `MP_JIRA_ISSUE_TYPE_ID=10204`.

After rerunning `jira:check` you should see

```raw
Checking issue type presence... OK
```

Which means that that issue type has been configured correctly.

#### Permissions

If `jira:check` shows

```raw
Trying to manipulate issue...
  - create issue... OK
  ...
  - update issue... OK
  - add comment to issue... OK
  - delete issue... OK
```

It means that user under which marketplace is accessing
JIRA has all the necessary permissions. If any of these
checks fail (apart from _delete_, which is optional)
you should make sure that correct permissions are set up to the user.

#### Workflow

At this point you should notice, that

```raw
  - check workflow transitions... FAIL
    - ERROR: Could not transition from 'TODO' to 'DONE' state,
      this will affect open access services
```

if failing, we will return to this later, after setting up workflow states.

```raw
Checking workflow...
  - todo [id: 1]... OK
  - in_progress [id: 2]... FAIL
    - ERROR: STATUS WITH ID: 2 DOES NOT EXIST IN JIRA
  - waiting_for_response [id: 3]... OK
  - done [id: 4]... FAIL
    - ERROR: STATUS WITH ID: 4 DOES NOT EXIST IN JIRA
  - rejected [id: 5]... OK

```

Shows that most workflow states are not correctly mapped.
You should look for `AVAILABLE ISSUE STATES`
(should be displayed near the end of the `jira:check` output)
All issue states are listed there, make sure you choose
issue states which are part of the workflow used
by the JIRA project to which marketplace is connected!

```raw
AVAILABLE ISSUE STATES:
  - Open [id: 1]
  - In progress [id: 3]
  - Resolved [id: 5]
  ...
```

using above suggestions you should configure following ENV variables:

- `MP_JIRA_WF_TODO`
- `MP_JIRA_WF_IN_PROGRESS`
- `MP_JIRA_WF_WAITING_FOR_RESPONSE`
- `MP_JIRA_WF_DONE`
- `MP_JIRA_WF_REJECTED`

So for example `MP_JIRA_WF_IN_PROGRESS=3`

After rerunning `jira:check` you should see something like this:

```raw
Checking workflow...
  - todo [id: 10309]... OK
  - in_progress [id: 3]... OK
  - waiting_for_response [id: 10310]... OK
  - done [id: 10311]... OK
  - rejected [id: 10103]... OK
```

Otherwise recheck assigned issue ids, and make sure
they are part of the same workflow, used by specified JIRA project

If everything is alright the following check

```raw
  - check workflow transitions... OK
```

should also pass, otherwise make sure that workflow in
JIRA has all the necessary transitions (from `TODO -> DONE`)

#### Custom fields

Marketplace makes use of a couple of custom fields which
have to be configured in order for system to function properly.
Unfortunately JIRA does not map custom fields by their names,
but by their IDs, so they have to be configured for
every JIRA instance separately. Fortunately `jira:check`
provides good suggestions about which ids should be matched with
which field:

```raw
Checking custom fields mappings... FAIL
  - ERROR: CUSTOM FIELD mapping have some problems
    - Order reference: ✕
    - CI-Name: ✕
    - CI-Surname: ✕
    - CI-Email: ✕
    - CI-DisplayName: ✕
    - CI-EOSC-UniqueID: ✕
    - CI-Institution: ✕
    - CI-Department: ✕
    - CI-DepartmentalWebPage: ✕
    - CI-SupervisorName: ✕
    - CI-SupervisorProfile: ✕
    - CP-CustomerTypology: ✕
    - CP-ReasonForAccess: ✕
    - CP-ScientificDiscipline: ✕
    - SO-1: ✕
SUGGESTED MAPPINGS
  - Order reference: customfield_10254 (export MP_JIRA_FIELD_Order_reference='customfield_10254')
  - CI-Name: customfield_10225 (export MP_JIRA_FIELD_CI_Name='customfield_10225')
  - CI-Surname: customfield_10226 (export MP_JIRA_FIELD_CI_Surname='customfield_10226')
  - CI-Email: customfield_10227 (export MP_JIRA_FIELD_CI_Email='customfield_10227')
  - CI-DisplayName: customfield_10228 (export MP_JIRA_FIELD_CI_DisplayName='customfield_10228')
  - CI-EOSC-UniqueID: customfield_10229 (export MP_JIRA_FIELD_CI_EOSC_UniqueID='customfield_10229')
  - CI-Institution: customfield_10243 (export MP_JIRA_FIELD_CI_Institution='customfield_10243')
  - CI-Department: customfield_10244 (export MP_JIRA_FIELD_CI_Department='customfield_10244')
  - CI-DepartmentalWebPage: customfield_10245 (export MP_JIRA_FIELD_CI_DepartmentalWebPage='customfield_10245')
  - CI-SupervisorName: customfield_10248 (export MP_JIRA_FIELD_CI_SupervisorName='customfield_10248')
  - CI-SupervisorProfile: customfield_10249 (export MP_JIRA_FIELD_CI_SupervisorProfile='customfield_10249')
  - CP-CustomerTypology: customfield_10250 (export MP_JIRA_FIELD_CP_CustomerTypology='customfield_10250')
  - CP-ReasonForAccess: customfield_10251 (export MP_JIRA_FIELD_CP_ReasonForAccess='customfield_10251')
  - CP-ScientificDiscipline: customfield_10252 (export MP_JIRA_FIELD_CP_ScientificDiscipline='customfield_10252')
  - SO-1: customfield_10400 (export MP_JIRA_FIELD_SO_1='customfield_10400')
AVAILABLE CUSTOM FIELDS
  ...
```

In suggested mappings you can see ENV variables assignments
which will fix given problem. If automatic match could not
be found you can look for list of custom fields
and their IDs in `AVAILABLE CUSTOM FIELDS` section of the output.

#### CP-CustomerTypology

This field is actually an option in JIRA.
So available option values must be provided. You need to configure
following variables:

- `MP_JIRA_FIELD_SELECT_VALUES_CP_CustomerTypology_single_user`
- `MP_JIRA_FIELD_SELECT_VALUES_CP_CustomerTypology_research`
- `MP_JIRA_FIELD_SELECT_VALUES_CP_CustomerTypology_private_company`

To ids of values which that particular custom field can take.
Unfortunately `jira:check` can not help you with this
one task, you have to ask either a JIRA admin,
or check yourself, if you have adequate permissions.

#### Webhooks

Webhook configuration has been described above in [Configuring webhook](#configuring-webhook)

Make sure to set `MP_JIRA_WEBHOOK_SECRET` variable to
the same value as the one in webhook, otherwise marketplace
will not receive any data from JIRA.

In order for `jira:check` to show you all problems with your webhook,
you need to set `MP_HOST` variable,
without it rake task will not be able to identify
which webhook is pointing to your application.

#### Summary

To sum up all the environmetnal variables which you need
to make sure to have set are below:

- `MP_JIRA_URL`
- `MP_JIRA_PROJECT`
- `MP_JIRA_USERNAME`
- `MP_JIRA_PASSWORD`
- `MP_JIRA_CONTEXT_PATH`
- `MP_JIRA_ISSUE_TYPE_ID`
- `MP_JIRA_WF_TODO`
- `MP_JIRA_WF_IN_PROGRESS`
- `MP_JIRA_WF_WAITING_FOR_RESPONSE`
- `MP_JIRA_WF_DONE`
- `MP_JIRA_WF_REJECTED`
- `MP_JIRA_WEBHOOK_SECRET`
- `MP_HOST`
- `MP_JIRA_PROJECT`
- `MP_JIRA_FIELD_Order_reference`
- `MP_JIRA_FIELD_CI_Name`
- `MP_JIRA_FIELD_CI_Surname`
- `MP_JIRA_FIELD_CI_Email`
- `MP_JIRA_FIELD_CI_DisplayName`
- `MP_JIRA_FIELD_CI_EOSC_UniqueID`
- `MP_JIRA_FIELD_CI_Institution`
- `MP_JIRA_FIELD_CI_Department`
- `MP_JIRA_FIELD_CI_SupervisorName`
- `MP_JIRA_FIELD_CI_SupervisorProfile`
- `MP_JIRA_FIELD_CP_CustomerTypology`
- `MP_JIRA_FIELD_CP_ReasonForAccess`
- `MP_JIRA_FIELD_CP_ScientificDiscipline`
- `MP_JIRA_FIELD_SO_1`
- `MP_JIRA_FIELD_CI_DepartmentalWebPage`
- `MP_JIRA_FIELD_SELECT_VALUES_CP_CustomerTypology_single_user`
- `MP_JIRA_FIELD_SELECT_VALUES_CP_CustomerTypology_research`
- `MP_JIRA_FIELD_SELECT_VALUES_CP_CustomerTypology_private_company`
- `MP_JIRA_FIELD_SELECT_VALUES_CP_CustomerTypology_project`
- `MP_JIRA_FIELD_SELECT_VALUES_CP_INeedAVoucher_true`
- `MP_JIRA_FIELD_SELECT_VALUES_CP_INeedAVoucher_false`
- `MP_JIRA_FIELD_SO_ServiceOrderTarget`
- `MP_JIRA_FIELD_CP_VoucherID`
- `MP_JIRA_FIELD_CP_INeedAVoucher`
- `MP_JIRA_FIELD_CP_Platforms`
- `MP_JIRA_FIELD_SO_ProjectName`
- `MP_JIRA_FIELD_CP_ProjectInformation`
- `MP_JIRA_FIELD_CP_UserGroupName`
