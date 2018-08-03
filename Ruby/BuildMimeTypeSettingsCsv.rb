# This file is not used in conjunction with the main script, but rather serves as
# a way to generate a new mime types CSV file from a given version of Nuix

require 'csv'

output_file = 'c:\temp\MimeTypeSettings.csv'

item_type_utility = $utilities.getItemTypeUtility
all_types = item_type_utility.getAllTypes
CSV.open(output_file,"w:utf-8") do |csv|
	csv << [
		"Kind",
		"LocalisedName",
		"PreferredExtension",
		"MimeType",
		"Enabled",
		"ProcessEmbedded",
		"ProcessText",
		"TextStrip",
		"ProcessNamedEntities",
		"ProcessImages",
		"StoreBinary",
	]

	all_types.sort_by{|t| [t.getKind.getName,t.getLocalisedName] }.each do |type|
		csv << [
			type.getKind.getName,
			type.getLocalisedName,
			type.getPreferredExtension,
			type.getName,
			true,
			true,
			true,
			false,
			true,
			true,
			true,
		]
	end
end