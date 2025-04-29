from paddleocr import PaddleOCR
import paddle
import time
import os
import sys

def process_image_with_ocr(ocr_instance, image_path):
    """使用OCR处理单个图片"""
    try:
        result = ocr_instance.ocr(image_path, cls=True)
        return result
    except Exception as e:
        print(f"OCR处理失败 ({image_path}): {str(e)}")
        return None

def extract_text_from_results(result):
    """从OCR结果中提取纯文本内容"""
    texts = []
    if not result:
        return texts
    
    for idx in range(len(result)):
        res = result[idx]
        for line in res:
            texts.append(line[1][0])
    return texts

def save_text_to_file(texts, output_path):
    """将文本内容保存到文件"""
    try:
        with open(output_path, 'w', encoding='utf-8') as f:
            for text in texts:
                f.write(text + '\n')
        return True
    except Exception as e:
        print(f"保存文件失败 ({output_path}): {str(e)}")
        return False

def ocr(folder:str, languages=''):
    # 检查GPU是否可用并显示信息
    if paddle.is_compiled_with_cuda():
        print("*********************************************************")
        print("可用的GPU数量:", paddle.device.cuda.device_count())
        print("当前使用的GPU:", paddle.device.get_device())
        print("*********************************************************")
        use_gpu = True
    else:
        print("未检测到GPU，将使用CPU进行处理")
        use_gpu = False
    
    # 创建OCR实例
    if languages == '':
        ocr = PaddleOCR(use_angle_cls=True, use_gpu=use_gpu)
    else:
        ocr = PaddleOCR(use_angle_cls=True, use_gpu=use_gpu, lang=languages)
    # 图片文件夹路径
    img_folder = folder
    # 确保图片文件夹存在
    if not os.path.exists(img_folder):
        print(f"错误：找不到图片文件夹 '{img_folder}'")
        sys.exit(1)    
    # 获取所有图片文件
    image_files = [f for f in os.listdir(img_folder) if f.lower().endswith(('.png', '.jpg', '.jpeg', '.bmp', '.tif', '.tiff'))]
    if not image_files:
        print(f"错误：在 '{img_folder}' 文件夹中未找到任何图片文件")
        sys.exit(1)    
    # 处理所有图片
    total_start_time = time.time()
    processed_count = 0
    
    print(f"开始处理 {len(image_files)} 个图片文件...")
    
    for img_file in image_files:
        img_path = os.path.join(img_folder, img_file)
        txt_file = os.path.splitext(img_file)[0] + '.txt'
        txt_path = os.path.join(img_folder, txt_file)
        print(f"正在处理: {img_file}")
        start_time = time.time()                        # 记录处理开始时间
        result = process_image_with_ocr(ocr, img_path)  # 处理图片
        process_time = time.time() - start_time         # 计算处理时间
        # 提取文本并保存
        if result:
            texts = extract_text_from_results(result)
            if texts:
                if save_text_to_file(texts, txt_path):
                    processed_count += 1
                    print(f"✓ 已保存OCR结果到: {txt_path} ({process_time:.2f}秒)")
                else:
                    print(f"✗ 无法保存OCR结果到: {txt_path}")
            else:
                print(f"✗ 未能从图片中提取文本: {img_file}")
        else:
            print(f"✗ OCR处理失败: {img_file}")
    
    # 计算总处理时间
    total_time = time.time() - total_start_time
    
    print("\n处理完成")
    print(f"总处理时间: {total_time:.2f}秒")
    print(f"成功处理: {processed_count}/{len(image_files)} 个图片")

if __name__ == "__main__":
    ocr('imgCN', 'ch')  # 处理文件夹中的图片，使用中文OCR模型
    ocr('imgEN', 'en')  # 处理文件夹中的图片，使用英文OCR模型