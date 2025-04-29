import pytesseract
from PIL import Image
def ocr_local_image(image_path):
    try:
        pytesseract.pytesseract.tesseract_cmd = r'D:\Programs\Tesseract-OCR\tesseract.exe'
        img = Image.open(image_path)
        text = pytesseract.image_to_string(img, lang='eng')
        return text.strip()
    except Exception as e:
        return "error"   

    
if __name__ == "__main__":
    result = ocr_local_image('img/2.jpg')  # 只使用英语模型，简化测试
    print(result)


    