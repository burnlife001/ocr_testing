# OCR测试项目

这是一个光学字符识别(OCR)测试项目，用于比较和评估不同OCR引擎的性能。

## 项目结构

- `ocr_Paddle.py` - 使用PaddleOCR引擎的OCR实现
- `ocr_Paddle_batch.py` - PaddleOCR的批处理实现
- `ocr_Tesseract.py` - 使用Tesseract引擎的OCR实现
- `ocr_Tesseract3.py` - Tesseract的改进版实现

## 测试数据

项目包含两组测试图像：
- `imgCN/` - 中文测试图像
- `imgEN/` - 英文测试图像

## 如何使用

1. 安装必要的依赖（Tesseract、PaddleOCR等）
2. 运行相应的脚本来处理图像文件
3. 查看生成的文本结果

## 环境设置

使用`venv_helper.ps1`脚本来设置虚拟环境。

## 贡献

欢迎提交问题和改进建议！