## Aplicación Móvil Swift

Esta aplicación móvil permite al usuario dibujar figuras geométricas en un lienzo interactivo y clasificar automáticamente la figura dibujada como círculo, cuadrado o triángulo, utilizando momentos invariantes de Hu o momentos de Zernike. El modelo de clasificación se basa en datos de referencia almacenados en un archivo CSV.

### Flujo

1.	El usuario dibuja una figura geométrica (círculo, cuadrado o triángulo) en el lienzo.
2.	Al presionar el botón “Capturar”, la aplicación convierte el dibujo a una imagen y la procesa.
3.	Dependiendo de la opción seleccionada (momentos de Hu o momentos de Zernike), se calculan los momentos correspondientes.
4.	Se compara la imagen con los datos de referencia almacenados en el CSV utilizando la distancia euclidiana.
5.	Se muestra el resultado de la clasificación en una alerta emergente.

### Estructura del Proyecto
* `ViewController.swift`: Controlador principal de la interfaz de usuario. Aquí se gestiona la captura del dibujo y la llamada al procesamiento de la imagen.
* `ZernikeBridge.h` y `ZernikeBridge.mm`: Implementación del puente entre Swift y C++ para calcular los momentos de Zernike y realizar la clasificación.
* `ImageProcessor.h` y `ImageProcessor.mm`: Implementación del procesamiento de imágenes en C++ para calcular los momentos de Hu y la clasificación correspondiente.
* `DrawingCanvasView.swift`: Clase que gestiona el lienzo interactivo donde el usuario puede dibujar.

### Cómo Funciona la Clasificación
1. Se convierte la imagen capturada del lienzo (UIImage) a una matriz OpenCV (cv::Mat).
2. Se aplica preprocesamiento a la imagen (escalado a grises y umbralización).
3. Se calculan los momentos invariantes:
* Momentos de Hu: Se utilizan 7 valores invariantes para la clasificación.
* Momentos de Zernike: Se calcula el orden deseado y se obtiene un vector de características.
4. Se compara el vector de momentos con los datos de referencia del archivo CSV usando la distancia euclidiana.
5. La categoría con la menor distancia es la predicción final.

### Ejemplos funcionamiento

![HUG](assets/hug.png "HUG")
![Zernike](assets/zernike.png "Zernike")