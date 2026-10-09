import pyodbc

conexion = pyodbc.connect(
    "DRIVER={ODBC Driver 17 for SQL Server};"
    "SERVER=localhost;"
    "DATABASE=DIRESA_La_Libertad;"
    "Trusted_Connection=yes;"
)

print("CONEXION EXITOSA")

conexion.close()