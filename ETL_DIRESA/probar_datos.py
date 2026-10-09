import pandas as pd
import pyodbc

conexion = pyodbc.connect(
    "DRIVER={ODBC Driver 17 for SQL Server};"
    "SERVER=localhost;"
    "DATABASE=DIRESA_La_Libertad;"
    "Trusted_Connection=yes;"
)

print("CONEXION EXITOSA")
print()

# Leer Prestaciones
prestaciones = pd.read_sql(
    "SELECT * FROM Prestaciones",
    conexion
)

# Leer Diagnósticos
diagnosticos = pd.read_sql(
    "SELECT * FROM Diagnosticos",
    conexion
)

# Leer Medicamentos
medicamentos = pd.read_sql(
    "SELECT * FROM Medicamentos",
    conexion
)

# Leer Establecimientos
establecimientos = pd.read_sql(
    "SELECT * FROM Establecimientos",
    conexion
)

print("DATOS EXTRAIDOS")
print("----------------------------")

print("Prestaciones:", len(prestaciones))
print("Diagnósticos:", len(diagnosticos))
print("Medicamentos:", len(medicamentos))
print("Establecimientos:", len(establecimientos))

print()
print("Primeras Prestaciones:")
print(prestaciones.head())

conexion.close()

print()
print("EXTRACCION COMPLETADA")