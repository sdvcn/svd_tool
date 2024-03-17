import std.stdio;
import std.getopt;

import ddsvd;

void main(string[] args)
{

	string svdFile;
	string jsonFile;



	auto helpInformation = getopt(
		args,
		"svd","input SVD file",  &svdFile,
		"json", "output JSON file",   &jsonFile,
		);    // enum

	if(svdFile is null || jsonFile is null)
	{
		
		helpInformation.helpWanted = true;
	}
	

	if (helpInformation.helpWanted)
	{
		defaultGetoptPrinter("Please specify input SVD file and output JSON file.\nsvd_tool svd to json converter",
			helpInformation.options);
		return;
	}

	writeln("Converting SVD to JSON...");
	writefln("Input SVD file: %s", svdFile);
	svdtojson(svdFile, jsonFile);
	writefln("Output JSON file: %s", jsonFile);
	writeln("Done!");
	
}
