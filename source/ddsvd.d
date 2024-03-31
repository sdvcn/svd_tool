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



import jsonwrap;




//enum svd_File = "STM32F401cc.svd";

alias DocType = DOMEntity!string;
alias DocAttrib = DocType.Attribute;

void svdtojson(string svdfile, string jsonfile)
{
    stdThreadLocalLog = new FileLogger(stdout, LogLevel.all);

    DocType doc = parseDOM!simpleXML(svdfile.readText());

    auto r1 = JSONValue.emptyObject;
    r1 = readEntity(doc.children);
    //auto j2 = JSONValue(doc.children());
    

    auto peris = r1.read!JSONValue("/device/peripherals/peripheral");

    
    foreach (ref JSONValue item; peris.array)
    {
        //
        if("derivedFrom" in item)
        {
            auto jsonStr = queryPeripherals(peris,item["derivedFrom"].str).toString;

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
    import std.bigint:BigInt;
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

	while(str.indexOf("\t",0,No.caseSensitive)>=0) 
    {
        str = str.replace("\t", "");
    }

	while(str.indexOf("\\t",0,No.caseSensitive)>=0) 
    {
        str = str.replace("\\t", "");
    }

    while(str.indexOf("  ",0,No.caseSensitive)>=0) 
    {
        str = str.replace("  ", " ");
    }

    str = str.stripLeft().stripRight();

	
    if(str.toLower() == "true")
    {
        return JSONValue(true);
    }

    if(str.toLower() == "false")
    {
        return JSONValue(false);
    }

    try{
        ulong ul = BigInt(str).toLong();
        return JSONValue(ul);
    }catch(Exception e){
    }
	

    return JSONValue(str);
}


/// 递归读取xml节点
JSONValue readEntity(DocType[] node,DocAttrib[] attrib = null)
in(!node.empty)
{
    if(node.length == 1)
    {
        if ( node[0].type == EntityType.text) return jsonclean(node[0].text);
    }

    JSONValue json = JSONValue.emptyObject;

    foreach ( val; attrib)
    {
        json[val.name] = jsonclean(val.value);
    }


    foreach (item; node)
    {
        if(item.type == EntityType.text){
            assert(false,"text node is not allowed");
        }
        
        if(item.type == EntityType.elementStart)
        {
            
            if(item.name.empty){
                json = readEntity(item.children);
            }else{

                if(item.isValueOne){

                    if(item.name in json)
                    {
                        if(json[item.name].type != JSONType.array)
                        {
                            auto swap = json[item.name];
                            json[item.name] = JSONValue.emptyArray;
                            json[item.name].array ~= swap;
                        }
                        json[item.name].array ~= readEntity(item.children);
                    }else{
                        json[item.name] = readEntity(item.children);
                    }
                }else{
                    if(item.name !in json)
                    {
                        json[item.name] = JSONValue.emptyArray;
                    }

                    if(json[item.name].type != JSONType.array)
                    {
                        auto swap = json[item.name];
                        json[item.name] = JSONValue.emptyArray;
                        json[item.name].array ~= swap;
                    }
                    json[item.name].array ~= readEntity(item.children,item.attributes);
                }
            }
        }
    }    
    return json;
}

/// 检查节点是否为一个value节点
bool isValueOne(DocType node)
{
    if(
        (node.children[0].type == EntityType.text)
    ) return true;

    if(
        (node.children[0].type == EntityType.elementStart)
    ) return true;

    return false;
}
