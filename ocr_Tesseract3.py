import os,sys
import pytesseract
from PIL import Image
import requests
from io import BytesIO

def set_tesseract_path():
    """设置Tesseract的路径"""
    if sys.platform.startswith('win'):
        # 用户指定的安装路径
        tesseract_path = r'D:\Programs\Tesseract-OCR\tesseract.exe'
        if os.path.exists(tesseract_path):
            pytesseract.pytesseract.tesseract_cmd = tesseract_path
            return True
            
        # Windows默认安装路径
        default_paths = [
            r'C:\Program Files\Tesseract-OCR\tesseract.exe',
            r'C:\Program Files (x86)\Tesseract-OCR\tesseract.exe'
        ]
        
        for path in default_paths:
            if os.path.exists(path):
                pytesseract.pytesseract.tesseract_cmd = path
                return True
                
        print(f"正在使用指定路径：{tesseract_path}")
        # 即使文件不存在，也强制设置路径（以防检查不准确）
        pytesseract.pytesseract.tesseract_cmd = tesseract_path
        return True
    return True  # 在Linux/Mac上通常不需要手动设置路径

def check_tesseract_installation():
    """检查Tesseract是否正确安装"""
    try:
        if not set_tesseract_path():
            print("错误：未找到Tesseract OCR。请按照以下步骤安装：")
            print("1. 访问 https://github.com/UB-Mannheim/tesseract/wiki")
            print("2. 下载并安装最新版本的Tesseract")
            print("3. 确保将Tesseract添加到系统环境变量PATH中")
            print("4. 重启您的Python IDE或命令行")
            return False
        return True
    except Exception as e:
        print(f"检查Tesseract安装时出错：{str(e)}")
        return False

def ocr_local_image(image_path, languages='eng'):
    """
    对本地图片进行OCR识别
    :param image_path: 图片路径
    :param languages: OCR语言，例如'eng'为英语，'chi_sim'为简体中文
    :return: 识别出的文本
    """
    try:
        if not os.path.exists(image_path):
            raise FileNotFoundError(f"找不到图片文件：{image_path}")
        
        if not check_tesseract_installation():
            raise RuntimeError("Tesseract OCR未正确安装")

        img = Image.open(image_path)
        text = pytesseract.image_to_string(img, lang=languages)
        return text.strip()
    except Exception as e:
        print(f"OCR处理失败：{str(e)}")
        return None

def ocr_remote_image(image_url, languages='eng'):
    """
    对网络图片进行OCR识别
    :param image_url: 图片URL
    :param languages: OCR语言，例如'eng'为英语，'chi_sim'为简体中文
    :return: 识别出的文本
    """
    try:
        if not check_tesseract_installation():
            raise RuntimeError("Tesseract OCR未正确安装")

        response = requests.get(image_url)
        response.raise_for_status()  # 确保请求成功
        img = Image.open(BytesIO(response.content))
        text = pytesseract.image_to_string(img, lang=languages)
        return text.strip()
    except requests.exceptions.RequestException as e:
        print(f"下载图片失败：{str(e)}")
        return None
    except Exception as e:
        print(f"OCR处理失败：{str(e)}")
        return None

def ocr_element_screenshot(element, languages='eng'):
    """
    对图片元素进行OCR识别
    :param element: PIL图像对象
    :param languages: OCR语言，例如'eng'为英语，'chi_sim'为简体中文
    :return: 识别出的文本
    """
    try:
        if not check_tesseract_installation():
            raise RuntimeError("Tesseract OCR未正确安装")

        if not isinstance(element, Image.Image):
            raise TypeError("输入必须是PIL图像对象")

        text = pytesseract.image_to_string(element, lang=languages)
        return text.strip()
    except Exception as e:
        print(f"OCR处理失败：{str(e)}")
        return None

if __name__ == "__main__":
    # 强制设置Tesseract路径
    set_tesseract_path()
    print(f"当前Tesseract路径: {pytesseract.pytesseract.tesseract_cmd}")
    
    # 检查Tesseract是否安装
    if not check_tesseract_installation():
        sys.exit(1)

    # 本地图片识别示例
    result = ocr_local_image('img/2.jpg', 'eng')  # 只使用英语模型，简化测试
    if result:
        print("识别结果：")
        print(result)
    else:
        print("OCR识别失败")

    # 网络图片识别示例（需要取消注释使用）
    """
    image_url = "https://example.com/image.jpg"
    result = ocr_remote_image(image_url, 'eng+chi_sim')
    if result:
        print("识别结果：")
        print(result)
    else:
        print("OCR识别失败")
    """
