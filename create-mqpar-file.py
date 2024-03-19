#!/usr/bin/python3
import xml.etree.ElementTree as ET
from os import listdir
import os
from os.path import join

tree = ET.parse('/proj/proteomics/bin/mqpar_QC_template.xml')
root = tree.getroot()
# get filenames which end with .raw and sort them
def find_raw_filenames(path_to_dir, suffix=".raw"):
    filenames = listdir(path_to_dir)
    return [filename for filename in filenames if filename.endswith(suffix) and "QC" in filename]
# define proj directory
projname = os.environ["projname"]
path = "/proj/proteomics/"+projname+"/data"
filenames = find_raw_filenames(path)
filenames.sort()
# change xml file
for i in range(len(filenames)):
    find = root.find("filePaths")
    define_tag = ET.SubElement(find, "string")
    define_tag.text = "/proj/proteomics/" + filenames[i]
    
    find = root.find("experiments")
    define_tag = ET.SubElement(find, "string")
    define_tag.text = str.split(filenames[i],".")[0]    

    find = root.find("fractions")
    define_tag = ET.SubElement(find, "short")
    define_tag.text = "32767"
    
    find = root.find("ptms")
    define_tag = ET.SubElement(find, "boolean")
    define_tag.text = "False"   
    
    find = root.find("paramGroupIndices")
    define_tag = ET.SubElement(find, "int")
    define_tag.text = "0" 
    
    find = root.find("referenceChannel")
    define_tag = ET.SubElement(find, "string")
    define_tag.text = "" 

# save results
# https://stackoverflow.com/questions/39890217/python-xml-modifying-by-elementtree-destroys-the-xml-structure
# https://stackoverflow.com/questions/3095434/inserting-newlines-in-xml-file-generated-via-xml-etree-elementtree-in-python
ET.indent(tree, '  ')
tree.write('/proj/proteomics/mqpar_tmp/mqpar_QC_updated.xml', method = "html", encoding="utf-8", xml_declaration=True)