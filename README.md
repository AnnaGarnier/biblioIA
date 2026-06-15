# BiblioIA — Sistema de Gestión de Biblioteca con Agente de IA

Trabajo Práctico Integrador — Base de Datos 2026  
UTN FRCU — Ingeniería en Sistemas de Información  


## Descripción

BiblioIA es un sistema de gestión de biblioteca que combina una base de datos relacional MySQL con un agente de inteligencia artificial capaz de responder preguntas en lenguaje natural (español) y generar recomendaciones personalizadas de libros.


## Tecnologías utilizadas

- MySQL 8+
- Python 3.10+
- Jupyter Notebook (VS Code)
- Google Gemini API (gemini-2.5-flash)
- Librerías: mysql-connector-python, pandas, python-dotenv, tabulate, google-genai


## Instalación y configuración

### 1. Requisitos previos
- MySQL 8+ instalado y corriendo
- Python 3.10+ o Anaconda
- VS Code con extensiones Python y Jupyter

### 2. Clonar el repositorio
```bash
git clone https://github.com/TU_USUARIO/BiblioIA.git
cd BiblioIA
```

### 3. Instalar dependencias
```bash
pip install mysql-connector-python python-dotenv google-genai pandas tabulate ipywidgets
```

### 4. Configurar variables de entorno

Crear un archivo `.env` en la raíz del proyecto con las siguientes variables:

\```
DB_HOST=localhost
DB_PORT=3306
DB_NAME=biblioia
DB_USER=root
DB_PASSWORD=tu_contraseña_de_mysql
LLM_API_KEY=tu_api_key_de_gemini
DB_SSL_CA=
\```

Para obtener una API key de Gemini gratis: https://aistudio.google.com/apikey

### 5. Crear la base de datos
Ejecutar en DBeaver, en este orden:
1. `01_ddl_schema.sql`
2. `02_dml_datos.sql`
3. `03_procedures.sql`
4. `04_triggers.sql`
5. `05_vistas.sql`

### 6. Ejecutar el notebook
Abrir `notebooks/BiblioIA.ipynb` y ejecutar todas las celdas con **Run All**.


## Uso del agente

```python
agente_responder("¿Cuáles son los 5 libros más prestados este año?")
recomendar_para(1)
```


## Notas de seguridad

- `.env` contiene credenciales y está excluido vía `.gitignore`
- Nunca subir el `.env` real a GitHub
- Usar `.env.example` como referencia