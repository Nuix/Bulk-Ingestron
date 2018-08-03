Bulk Ingestron
==============

![Last tested in Nuix 7.4](https://img.shields.io/badge/Nuix-7.4-green.svg)

View the GitHub project [here](https://github.com/Nuix/Bulk-Ingestron) or download the latest release [here](https://github.com/Nuix/Bulk-Ingestron/releases).

# Overview

**Written By:** Jason Wells

This script provides a way to bulk ingest data into one or more cases based on an input CSV and series of settings files.  This script is intended to be ran using `nuix_console.exe` and is almost entirely headless except for a prompt to pick an input CSV file.

# Getting Started

## Setup

Begin by downloading the latest release of this code.  Extract the contents of the archive into a directory.  Configure the various settings files as noted below.  Build an input CSV (see included example for template).  Run `BulkIngestron.rb` via `nuix_console.exe` with a command such as:

```
"C:\Program Files\Nuix\Nuix 7.4\nuix_console.exe" ^
-Dfile.encoding=utf8 ^
-Xms2g -Xmx24g ^
-licencesourcetype dongle ^
-licenceworkers 4 ^
"C:\Scripts\BulkIngestron\BulkIngestron.rb"
```

When prompted, select the input CSV file you created.

## Settings Files

### ProcessingSettings.json

This is a JSON file containing the various ingestion settings to be used.  If a value is set to `null`, then Nuix will use its default values.  See API documentation for [Processor.setProcessingSettings][setProcessingSettings].

### ParallelProcessingSettings.json

This is a JSON file containing the various worker settings to be used.  If a value is set to `null`, then Nuix will use its default values.  See API documentation for [ParallelProcessingConfigurable.setParallelProcessingSettings][setParallelProcessingSettings].

### OcrSettings.json

This is a JSON file containing OCR settings which will be used if **performOcrPostIngestion** is set to `true` in [GeneralSettings.json].  If a value is set to `null`, then Nuix will use its default values.  See API documentation for [OcrProcessor.process](https://download.nuix.com/releases/desktop/stable/docs/en/scripting/api/nuix/OcrProcessor.html#process-java.util.List-java.util.Map-) for details on available settings.

**Note:** In addition to those settings there is a setting `ocrProfileName` which may be used to instead specify an OCR profile to use.  Note that when a value is provided for this setting, the *other settings in this file are ignored*.  This setting is only supported when using **Nuix 7.4** and up.

### EvidenceSettings.json

This is a JSON file containing the evidence settings to use.  If a value is set to `null`, then Nuix will use defaults based on the current machine.

### GeneralSettings.json

This JSON file contains settings not specific to Nuix.

- **sleepBetweenJobs**: The number of seconds the script should wait after completing a job, before starting the next job.  This setting was added because in some situations worker licence release may take a moment.
- **ignoreUnknownMimeTypes**: This setting relates to how unknown mime types found in [MimeTypeSettings.csv] are handled.  When `true`, unknown mime types will log a warning but processing will proceed anyways.  When `false`, the script will intentionally halt before processing begins if unknown mime types are present in [MimeTypeSettings.csv].  The available mime types are checked against those which Nuix reports are available using a call to ```Utilities.getItemUtility.getAllTypes```.
- **allowCaseMigration**: When `true` you are giving Nuix permission to migrate older cases which may be opened by this script to the current version of Nuix running the script.  When `false` you are denying permission to Nuix to migrate cases.  If this is set to `false` and the case requires migration, the particular ingestion will be skipped.
- **additionalReportingScope**:  When ingestion completes, some numbers are gather and recorded regarding evidence total items, evidence audited items, etc.  These numbers are scoped to the evidence just added.  This setting allows you to specify additional scoping criteria in the form of a Nuix query.  This allows you to further excluded what items may be reported, for example to excluded certain kinds of error items.  If this value is `null` or empty, it has no effect.
- **performIngestion**: Allows you to turn off the ingestion step.  This setting is intended to be set to `false` only when `performOcrPostIngestion` is set to `true`.  The intended use is to allow you to run the script in an OCR only pass, using the same input file used to perform the ingestions.
- **performOcrPostIngestion**: Determines whether OCR will be performed against the items just ingested.  When `true` OCR will be performed.  When `false` no OCR will be performed.  Items which are OCR'ed when `true` will be limited to items present in the just added evidence and those responsive to the query provided in `postIngestionOcrQuery`.  Settings used to perform OCR are specified in the file [OcrSettings.json](#ocrsetting-json) and worker settings used are determined by those provided in [ParallelProcessingSettings.json](#parallelprocessingsettings-json).
- **postIngestionOcrQuery**: In addition to being scoped to the evidence just added, this query determines which items will be OCR'ed when `performOcrPostIngestion` is `true`.
- **keyStoreFile**: If a path to a key store CSV is provided for this setting, keystore entries will be added to the processor before each ingestion.  See [Key Store File](#key-store-file) for more details.  **Note:** In JSON a `\` is a special character so when providing a path to a key store file using this setting `\` needs to be escaped as `\\`.  For example `C:\Path\KeyStoreData.csv` needs to be provided as `"C:\\Path\\KeyStoreData.csv"`.

### MimeTypeSettings.csv

This is a CSV in which you can specify settings for specific mime types.  The CSV contains the following columns:

- **Kind**: The particular kind, for reference only
- **LocalisedName**: The "friendly" name of the type, for reference only
- **PreferredExtension**: The commonly known extension for the type, for reference only
- **MimeType**: The mime type, should match values in Nuix
- **Enabled**: see below
- **ProcessEmbedded**: see below
- **ProcessText**: see below
- **TextStrip**: see below
- **ProcessNamedEntities**: see below
- **ProcessImages**: see below
- **StoreBinary**: see below

You can specify what will or will not be processed for various Mime Types by setting the relevant column to `true` or `false`.  For additional details about the last several columns refer to the API documentation for [Processor.setMimeTypeProcessingSettings][setMimeTypeProcessingSettings].

**Note:** If a record is not present for a given type, nothing is set and Nuix will use it's defaults for that type (see API doc link above).

**Important:** When the script loads mime type settings from [MimeTypeSettings.csv](#mimetypesettings-csv) they will be checked against those present in your version of Nuix.  Depending on your configuration, unrecognized mime types will either be ignored or the script will halt.  See [GeneralSettings.json](#generalsettings-json) for details.

### SleepScheduleSettings.json

This is a JSON formatted file which contains information about when the script should sleep.  When the script detects the current time is within a scheduled sleep time it will enter an idle loop until the scheduled sleep time has ended.  The sleep schedule is checked at the following points during processing:

- Before starting the next job
- Before ingestion begins for a given job
- During ingest for a given job
- Before starting OCR for a given job
- During OCR of a given job

The default schedule settings specify no sleep times:

```javascript
{
	"sunday": {
		"sleep_start": "",
		"sleep_stop": ""
	},
	"monday": {
		"sleep_start": "",
		"sleep_stop": ""
	},
	"tuesday": {
		"sleep_start": "",
		"sleep_stop": ""
	},
	"wednesday": {
		"sleep_start": "",
		"sleep_stop": ""
	},
	"thursday": {
		"sleep_start": "",
		"sleep_stop": ""
	},
	"friday": {
		"sleep_start": "",
		"sleep_stop": ""
	},
	"saturday": {
		"sleep_start": "",
		"sleep_stop": ""
	}
}
```

To configure a sleep time for a given day, you must provide a time such as `6:00 AM` or `5:45 PM` in both `sleep_start` and `sleep_stop` for the given day.  Blank time values for either specify no sleep time for the given day.

Imagine you wished to setup the sleep schedule for the following:

- No sleeping on Saturday and Sunday (servers are available all day)
- Sleep 8:00 AM - 5:00 PM Monday thru Thursday (during office hours, servers are in use)
- Sleep 9:00 AM - 2:00 PM on Friday (shorter office hours so sleep time is shorter)

You could provided a JSON file like the following:

```javascript
{
	"sunday": {
		"sleep_start": "",
		"sleep_stop": ""
	},
	"monday": {
		"sleep_start": "8:00 AM",
		"sleep_stop": "5:00 PM"
	},
	"tuesday": {
		"sleep_start": "8:00 AM",
		"sleep_stop": "5:00 PM"
	},
	"wednesday": {
		"sleep_start": "8:00 AM",
		"sleep_stop": "5:00 PM"
	},
	"thursday": {
		"sleep_start": "8:00 AM",
		"sleep_stop": "5:00 PM"
	},
	"friday": {
		"sleep_start": "9:00 AM",
		"sleep_stop": "2:00 PM"
	},
	"saturday": {
		"sleep_start": "",
		"sleep_stop": ""
	}
}
```

### ElasticCaseSettings.json

This file is where you may provide Elastic Search cluster information which will be used when the script needs to create a case which will reside in an Elastic Search cluster.

```javascript
{
  "clusters": [
    {
      "notes": "Test Environment",
      "cluster.name": "cluster1",
      "index.number_of_shards": 10,
      "index.number_of_replicas": 1,
      "nuix.transport.hosts": [
        "host1",
        "host2",
        "etc"
      ]
    },
    {
      "notes": "Production environment",
      "cluster.name": "cluster2",
      "index.number_of_shards": 10,
      "index.number_of_replicas": 1,
      "nuix.transport.hosts": [
        "hostA",
        "hostB",
        "etc"
      ]
    }
  ]
}
```

The `clusters` array can contain one or more hashes, each of which can contain the following:

```table
Key | Description
**notes** | This entry is for your own notes and will be ignored/not provided to Nuix.
**cluster.name** | The name of the cluster.  This is also the name you would provide in your input CSV for **Cluster Name**.
**index.number_of_shards** | See [Nuix docs](https://download.nuix.com/releases/desktop/stable/docs/en/scripting/api/nuix/CaseFactory.html#create-java.io.File-java.util.Map-).
**index.number_of_replicas** | See [Nuix docs](https://download.nuix.com/releases/desktop/stable/docs/en/scripting/api/nuix/CaseFactory.html#create-java.io.File-java.util.Map-).
**nuix.transport.hosts** | See [Nuix docs](https://download.nuix.com/releases/desktop/stable/docs/en/scripting/api/nuix/CaseFactory.html#create-java.io.File-java.util.Map-).
```

If a given script run will not be creating any Elastic Search based Nuix cases, this can be ignored.

## Input Files

### Input CSV

Input CSV is expected to have a headers row.  It is also expected to have the following columns in the following order with these exact headers:

- **Case Name**: What to name the case if it needs to be created.
- **Case Directory**: The directory of the case to use.  If the case does not exist it will be created.  If the case does exist it will be opened.
- **Cluster Name**: If this row will be creating a case that does not already exist and the case to be created is an elastic search case, this is where you provide a cluster name as noted in `ElasticCaseSettings.json` as `cluster.name` that the case should be created in.  Note that value provided here should match exactly the value specified in `ElasticCaseSettings.json` for `cluster.name`.  See [here](#elasticcasesettings-json) for more details about this settings file.
- **Evidence Name**: Name of the evidence to be created.
- **Evidence Comments**: Comments which will be applied to the evidence container item.
- **Custodian**: The custodian to assign to the evidence.
- **Source Path**: The path to the source data.  If this is a directory Nuix will ingest all data in the directory.  If this is a absolute file path, just the file will be processed.

You may in addition add columns with whatever header names you would like.  Any additional columns are added as custom metadata to the evidence container using the headers as the custom metadata name and cell value as the value to assign.

You can specify multiple paths for a single evidence by separating the paths in **Source Path** with a `;`

```
C:\path1;C:\path2;C:\path3
```

See `SampleInput.csv` included with this script for an example input file.

### Key Store File

When the general settings JSON file contains the path to a CSV file, the entries in this CSV will be added to the processor key store before each ingestion.  Entries are added by specifying the target source data as `*` which means the script leaves Nuix to figure out which ID file is associated to which source data.

The key store CSV is expected to have the following columns in this order, with headers:

```table
Column | Description
**KeyFile** | The absolute path to an appropriate key file.
**Password** | The password Nuix will use to access this key file.
**TargetEvidenceName** | *(optional)* If a value if provided, this key will only be loaded to the key store while processing the evidence with the same name in the input CSV.  Names are matched case insensitive.
```

An example key file CSV might look something like this:

```table
KeyFile | Password | TargetEvidenceName
C:\Keys\NsfKey01.id | secretpassword | 
C:\Keys\NsfKey02.id | mittensthekitten | Evidence001
```

See included `ExampleKeyStoreFile.csv` for a starter template CSV.

## Output Files

While running three files are created and updated, named with a timestamp.

- All output written to standard out will also be logged to a log file `{TIMESTAMP}_Log.txt`
- After each individual ingestion job is completed it will either be recorded to the error report or the success report depending on whether there were any errors.

**IMPORTANT**: Do not open the output CSV files until the script completes as this could cause a file permissions error!

### Error Report

`{TIMESTAMP}_Errored.csv`

- Case Name
- Case Directory
- Evidence Name
- Evidence Comments
- Custodian Name
- Source Path
- *.. Any Custom Metadata Columns You Defined ...*
- Error Message

### Success Report

`{TIMESTAMP}_Successful.csv`

- Case Name
- Case Directory
- Evidence Name
- Evidence Comments
- Custodian Name
- Source Path
- *.. Any Custom Metadata Columns You Defined ...*
- Total Item Count
- Total Emails Count
- Total Audited Item Count
- Total Audited Size GB
- Total OCR Items
- Ingestion Elapsed
- OCR Elapsed
- Total Elapsed

# License

```
Copyright 2018 Nuix

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
```