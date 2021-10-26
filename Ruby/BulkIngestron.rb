require "csv"
require "json"
require "thread"

script_directory = File.dirname(__FILE__).gsub("\\","/")
load File.join(script_directory,"Dialogs.rb_")
load File.join(script_directory,"Logger.rb_")
load File.join(script_directory,"NuixVersion.rb_")
load File.join(script_directory,"RubyClassExtensions.rb_")
load File.join(script_directory,"IngestionJob.rb_")
load File.join(script_directory,"SleepScheduler.rb_")

#=============#
# DO THE WORK #
#=============#
input_csv_path = Dialogs.prompt_open_csv(script_directory,"Select Input CSV")
if input_csv_path.nil? || !input_csv_path.exists
	Dialogs.show_error("You must select an input file to proceed")
	exit 1
else
	input_csv_path = input_csv_path.getAbsolutePath
end

start_time = Time.now
time_stamp = Time.now.strftime("%Y%m%d_%H-%M-%S")

#Setup logging
log_directory = File.join(script_directory,"Logs").gsub("\\","/")
if !java.io.File.new(log_directory).exists
	java.io.File.new(log_directory).mkdirs
end
Logger.log_file = File.join(log_directory,"#{time_stamp}_Log.txt")
Logger.log("Log File: #{Logger.log_file}")

#Load settings JSON/CSV files
IngestionJob.load_passwords_file(File.join(script_directory,"Passwords.txt"))
IngestionJob.load_processing_settings(File.join(script_directory,"ProcessingSettings.json"))
IngestionJob.load_ocr_settings(File.join(script_directory,"OcrSettings.json"))
IngestionJob.load_parallel_processing_settings(File.join(script_directory,"ParallelProcessingSettings.json"))
IngestionJob.load_evidence_settings(File.join(script_directory,"EvidenceSettings.json"))
IngestionJob.load_general_settings(File.join(script_directory,"GeneralSettings.json"))
IngestionJob.load_elastic_case_settings(File.join(script_directory,"ElasticCaseSettings.json"))
begin
	IngestionJob.load_mime_type_settings(File.join(script_directory,"MimeTypeSettings.csv"))
rescue Exception => exc
	Logger.log("Error while loading mime type settings: #{exc.message}")
	Logger.log("Exiting")
	exit 1
end

#Load sleep schedule into SleepScheduler
Logger.log("Loading sleep schedule data...")
SleepScheduler.load_schedule_data(File.join(script_directory,"SleepScheduleSettings.json"))

#DEBUG: Testing sleep scheduler
#SleepScheduler.schedule_data[:monday][:sleep_start] = (Time.now + 60).to_s
#SleepScheduler.schedule_data[:monday][:sleep_stop] = (Time.now + 120).to_s

Logger.log("Today's Sleep Schedule: #{SleepScheduler.todays_sleep_schedule}")

#Set reporting files
IngestionJob.error_report_path = File.join(log_directory,"#{time_stamp}_Errored.csv")
IngestionJob.success_report_path = File.join(log_directory,"#{time_stamp}_Successful.csv")

#Report settings
IngestionJob.dump_settings

#Get current Nuix version
current_nuix_version = NuixVersion.current
Logger.log("Nuix Version: #{current_nuix_version}")
requested_processing_workers = IngestionJob.parallel_processing_settings["workerCount"]
Logger.log("ParallelProcessingSettings.json Workers: #{requested_processing_workers}")
#Show worker count if Nuix version supports this
if current_nuix_version >= 6.2
	#getWorkers was added in 6.2
	available_workers = $utilities.getLicence.getWorkers
	Logger.log("Acquired Licence Workers: #{available_workers}")
	#Check if parallel processing settings is requesting more than available
	if requested_processing_workers > available_workers
		Logger.log("WARNING: Settings requested more workers than acquired licence has available!")
	end
end

ingestion_jobs = IngestionJob.from_csv(input_csv_path)
if ingestion_jobs.nil? == false
	Logger.log("Jobs in Input File: #{ingestion_jobs.size}")
	ingestion_jobs.each_with_index do |job,index|
		Logger.log("==== #{index+1}/#{ingestion_jobs.size} ====")
		job.go
		sleep_seconds = IngestionJob.general_settings["sleepBetweenJobs"]
		Logger.log("Sleeping #{sleep_seconds} seconds before starting next job...")
		sleep(sleep_seconds)
	end
end
finish_time = Time.now
Logger.log("Completed in #{Time.at(finish_time-start_time).gmtime.strftime("%H:%M:%S")}")