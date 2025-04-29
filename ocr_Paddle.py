from paddleocr import PaddleOCR
import paddle
import time

ocr = PaddleOCR(use_angle_cls=True)
def process_image_with_ocr(image_path):
    try:
        result = ocr.ocr(image_path, cls=True)
        return result
    except Exception as e:
        print(f"OCR处理失败：{str(e)}")
        return None

# 检查GPU是否可用并显示信息
if paddle.is_compiled_with_cuda():
    print("*********************************************************")
    print("可用的GPU数量:", paddle.device.cuda.device_count())
    print("当前使用的GPU:", paddle.device.get_device())
    print("*********************************************************")
# 明确指定使用GPU
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

def main():
    # 创建OCR实例
    ocr = PaddleOCR(use_gpu=True, gpu_mem=500, lang='ch')
    img_path = 'img/4.jpg'    
    # 记录处理开始时间
    start_time = time.time()    
    # 使用process_image_with_ocr函数处理图片
    result = process_image_with_ocr(img_path)    
    # 计算处理时间
    process_time = time.time() - start_time
    print(f"\n处理时间: {process_time:.2f}秒")
    
    # 获取并打印识别结果
    if result:
        texts = extract_text_from_results(result)
        print("\n识别文本:")
        for text in texts:
            print(text)

if __name__ == "__main__":
    main()