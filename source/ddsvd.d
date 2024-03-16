module ddsvd;

import dxml.parser;
import dxml.dom;;

import std.logger;
import std.stdio;
import std.json;
import std.file:readText;
import std.range.primitives:empty;
import std.string:replace,indexOf,isNumeric,toLower,stripLeft,stripRight;
import std.typecons:Yes,No;

import std.conv:to;



//import jsonwrap;




//enum svd_File = "STM32F401cc.svd";

alias DocType = DOMEntity!string;
alias DocAttrib = DocType.Attribute;

void svdtojson(string svdfile, string jsonfile)
{
    stdThreadLocalLog = new FileLogger(stdout, LogLevel.all);

    DocType doc = parseDOM!simpleXML(svdfile.readText());

    auto r1 = readNode(doc.children);
    //auto j2 = JSONValue(doc.children());

    foreach (ref JSONValue item; r1["device"]["peripherals"]["peripheral"].array)
    {
        //
        if("derivedFrom" in item)
        {
            auto jsonStr = queryPeripherals(r1["device"]["peripherals"]["peripheral"],item["derivedFrom"].str).toString;

            JSONValue temp = parseJSON(jsonStr);
            
            foreach (string mkey, JSONValue mval; item)
            {
                if(mkey == "derivedFrom") continue;
                temp[mkey] = mval;
            }
            item = temp;
        }
    }

    r1.toJSON(false,JSONOptions.doNotEscapeSlashes).toFile(jsonfile);
}
/// 查询外围设备
JSONValue queryPeripherals(JSONValue json,string name) 
in(json.type == JSONType.array)
{
    foreach(JSONValue item; json.array.dup)
    {
        if(item["name"].str == name){
            return item;
        }
    }
    return JSONValue.emptyObject;
}


/// 整理json值
JSONValue jsonclean(string val)
{
    auto str = val;
	while(str.indexOf("\n",0,No.caseSensitive)>=0) 
    {
        str = str.replace("\n", "");
    }
	while(str.indexOf("\\n",0,No.caseSensitive)>=0) 
    {
        str = str.replace("\\n", "");
    }

	while(str.indexOf("\r",0,No.caseSensitive)>=0) 
    {
        str = str.replace("\r", "");
    }
	while(str.indexOf("\\r",0,No.caseSensitive)>=0) 
    {
        str = str.replace("\\r", "");
    }

	while(str.indexOf("\t",0,No.caseSensitive)>=0) {
        str = str.replace("\t", "");
    }

	while(str.indexOf("\\t",0,No.caseSensitive)>=0) {
        str = str.replace("\\t", "");
    }

    while(str.indexOf("  ",0,No.caseSensitive)>=0) 
    {
        str = str.replace("  ", " ");
    }

    str = str.stripLeft().stripRight();

	/*
    if(str.toLower() == "true")
    {
        return JSONValue(true);
    }

    if(str.toLower() == "false")
    {
        return JSONValue(false);
    }

    try{
        ulong ul = str.to!ulong;
        return JSONValue(ul);
    }catch(Exception e){
    }
	*/

    return JSONValue(str);
}


/// 递归读取xml节点
JSONValue readNode(DocType[] node,DocAttrib[] attrib = null)
//in(node.type == EntityType.elementStart)
in(node.length > 0)
{
    if(node.length == 1 && node[0].type == EntityType.text){
        /// 过滤文本中所有的换行符
        //auto str = node[0].text.replace("\n", "").replace("\r", "");
        //return jsonclean(str);
		return jsonclean(node[0].text);
    }


    JSONValue json = JSONValue.emptyObject;

    foreach ( val; attrib)
    {
        json[val.name] = jsonclean(val.value);
    }


    foreach (item; node)
    {
        if(item.type == EntityType.text){
        }
        
        if(item.type == EntityType.elementStart)
        {
            
            if(item.name.empty){
                json = readNode(item.children);
            }else{
                if(item.name in json)
                {
                    if(json[item.name].type == JSONType.array){
                        json[item.name].array ~= readNode(item.children,item.name.empty? null:item.attributes);
                    }else{
                        auto swap = json[item.name];
                        json[item.name] = JSONValue.emptyArray;
                        json[item.name].array ~= swap;
                        json[item.name].array ~= readNode(item.children,item.name.empty? null:item.attributes);
                    }
                }else{
                    json[item.name] = readNode(item.children,item.name.empty? null:item.attributes);
                }
            }
        }
        
        
    }
    
    return json;
}


