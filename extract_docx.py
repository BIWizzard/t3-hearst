import zipfile
import xml.etree.ElementTree as ET

with zipfile.ZipFile("D&A MVP&SOW2 4.13.26wk Agenda.docx", 'r') as zip_ref:
    xml_content = zip_ref.read('word/document.xml')
    
root = ET.fromstring(xml_content)

ns = {'w': 'http://schemas.openxmlformats.org/wordprocessingml/2006/main'\}

texts = []
for text_elem in root.findall('.//w:t', ns):
    if text_elem.text:
        texts.append(text_elem.text)

content = ''.join(texts)
print(content)
