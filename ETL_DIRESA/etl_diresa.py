import pyodbc
import pandas as pd
from datetime import datetime


# ============================================================
# CONFIGURACIÓN
# ============================================================

SERVIDOR = "localhost"

BASE_FUENTE = "DIRESA_La_Libertad"
BASE_DW = "DW_DIRESA_La_Libertad"

ARCHIVO_LOG = "etl_log.txt"


# ============================================================
# FUNCIÓN PARA ESCRIBIR EN EL LOG
# ============================================================

def escribir_log(mensaje):

    fecha_hora = datetime.now().strftime("%Y-%m-%d %H:%M:%S")

    linea = f"[{fecha_hora}] {mensaje}"

    print(linea)

    with open(ARCHIVO_LOG, "a", encoding="utf-8") as archivo:
        archivo.write(linea + "\n")


# ============================================================
# CONEXIONES
# ============================================================

def conectar_base(nombre_base):

    return pyodbc.connect(
        "DRIVER={ODBC Driver 17 for SQL Server};"
        f"SERVER={SERVIDOR};"
        f"DATABASE={nombre_base};"
        "Trusted_Connection=yes;"
    )


# ============================================================
# INICIO DEL ETL
# ============================================================

try:

    # Limpiar log anterior
    with open(ARCHIVO_LOG, "w", encoding="utf-8") as archivo:
        archivo.write("LOG DEL PROCESO ETL DIRESA\n")
        archivo.write("=" * 60 + "\n")

    escribir_log("INICIANDO PROCESO ETL")


    # ========================================================
    # CONECTAR A FUENTE
    # ========================================================

    conexion_fuente = conectar_base(BASE_FUENTE)

    escribir_log("CONEXIÓN A FUENTE: OK")


    # ========================================================
    # CONECTAR AL DATA WAREHOUSE
    # ========================================================

    conexion_dw = conectar_base(BASE_DW)

    escribir_log("CONEXIÓN AL DATA WAREHOUSE: OK")


    # ========================================================
    # EXTRACCIÓN
    # ========================================================

    escribir_log("INICIANDO EXTRACCIÓN")


    prestaciones = pd.read_sql(
        "SELECT * FROM Prestaciones",
        conexion_fuente
    )

    diagnosticos = pd.read_sql(
        "SELECT * FROM Diagnosticos",
        conexion_fuente
    )

    medicamentos = pd.read_sql(
        "SELECT * FROM Medicamentos",
        conexion_fuente
    )

    establecimientos = pd.read_sql(
        "SELECT * FROM Establecimientos",
        conexion_fuente
    )


    escribir_log(f"Prestaciones extraídas: {len(prestaciones)}")
    escribir_log(f"Diagnósticos extraídos: {len(diagnosticos)}")
    escribir_log(f"Medicamentos extraídos: {len(medicamentos)}")
    escribir_log(f"Establecimientos extraídos: {len(establecimientos)}")


    print()
    print("DATOS EXTRAÍDOS")
    print("-----------------------------")
    print("Prestaciones:", len(prestaciones))
    print("Diagnósticos:", len(diagnosticos))
    print("Medicamentos:", len(medicamentos))
    print("Establecimientos:", len(establecimientos))


    # ========================================================
    # TRANSFORMACIÓN
    # ========================================================

    escribir_log("INICIANDO TRANSFORMACIÓN")


    # --------------------------------------------------------
    # LIMPIEZA DE TEXTOS
    # --------------------------------------------------------

    tablas = [
        prestaciones,
        diagnosticos,
        medicamentos,
        establecimientos
    ]

    for tabla in tablas:

        for columna in tabla.columns:

            if (
                pd.api.types.is_object_dtype(tabla[columna])
                or pd.api.types.is_string_dtype(tabla[columna])
            ):

                tabla[columna] = (
                    tabla[columna]
                    .astype("string")
                    .str.strip()
                )


    # --------------------------------------------------------
    # CONVERSIÓN DE FECHAS
    # --------------------------------------------------------

    prestaciones["FECHA_CORTE"] = pd.to_datetime(
        prestaciones["FECHA_CORTE"],
        errors="coerce"
    )

    prestaciones["FECHA_ATENCION"] = pd.to_datetime(
        prestaciones["FECHA_ATENCION"],
        errors="coerce"
    )

    establecimientos["INICIO_ACTIVIDAD"] = pd.to_datetime(
        establecimientos["INICIO_ACTIVIDAD"],
        errors="coerce"
    )


    # --------------------------------------------------------
    # ELIMINAR DUPLICADOS
    # --------------------------------------------------------

    prestaciones = prestaciones.drop_duplicates(
        subset=["ID_REGISTRO_REL"]
    )

    diagnosticos = diagnosticos.drop_duplicates()

    medicamentos = medicamentos.drop_duplicates()

    establecimientos = establecimientos.drop_duplicates(
        subset=["CODIGO_UNICO"]
    )


    # ========================================================
    # DIM_FECHA
    # ========================================================

    fechas = prestaciones[
        ["FECHA_ATENCION"]
    ].dropna().drop_duplicates().copy()

    fechas["fecha"] = fechas["FECHA_ATENCION"].dt.date

    fechas["fecha_key"] = (
        prestaciones["FECHA_ATENCION"]
        .dt.strftime("%Y%m%d")
    )

    fechas = prestaciones[
        ["FECHA_ATENCION"]
    ].dropna().drop_duplicates().copy()

    fechas["fecha_key"] = (
        fechas["FECHA_ATENCION"]
        .dt.strftime("%Y%m%d")
        .astype(int)
    )

    fechas["fecha"] = fechas["FECHA_ATENCION"].dt.date

    fechas["dia"] = fechas["FECHA_ATENCION"].dt.day

    fechas["mes"] = fechas["FECHA_ATENCION"].dt.month

    fechas["nombre_mes"] = fechas[
        "FECHA_ATENCION"
    ].dt.month_name()

    fechas["trimestre"] = fechas[
        "FECHA_ATENCION"
    ].dt.quarter

    fechas["anio"] = fechas[
        "FECHA_ATENCION"
    ].dt.year


    # ========================================================
    # DIM_MEDICAMENTO
    # ========================================================

    dim_medicamento = medicamentos[
        ["COD_MEDICAMENTO"]
    ].dropna().drop_duplicates().copy()

    dim_medicamento = dim_medicamento.reset_index(drop=True)

    dim_medicamento["medicamento_key"] = (
        dim_medicamento.index + 1
    )


    # ========================================================
    # DIM_DIAGNOSTICO
    # ========================================================

    dim_diagnostico = diagnosticos[
        [
            "CODDIA",
            "TIPO_DIAGNOSTICO"
        ]
    ].drop_duplicates().copy()

    dim_diagnostico = dim_diagnostico.dropna(
        subset=["CODDIA"]
    )

    dim_diagnostico = dim_diagnostico.reset_index(drop=True)

    dim_diagnostico["diagnostico_key"] = (
        dim_diagnostico.index + 1
    )


    # ========================================================
    # DIM_ESTABLECIMIENTO
    # ========================================================

    columnas_establecimiento = [
        "CODIGO_UNICO",
        "INSTITUCION",
        "NOMBRE_ESTABLECIMIENTO",
        "CLASIFICACION",
        "TIPO",
        "DEPARTAMENTO",
        "PROVINCIA",
        "DISTRITO",
        "UBIGEO",
        "DIRECCION",
        "CODIGO_DISA",
        "CODIGO_RED",
        "CODIGO_MICRORED",
        "DISA",
        "RED",
        "MICRORED",
        "CODIGO_UE",
        "UNIDAD_EJECUTORA",
        "CATEGORIA",
        "TELEFONO",
        "TIPO_DOC_CATEGORIZACION",
        "NRO_DOC_CATEGORIZACION",
        "HORARIO",
        "INICIO_ACTIVIDAD",
        "DIRECTOR_RESPONSABLE",
        "ESTADO",
        "SITUACION",
        "CONDICION",
        "INSPECCION",
        "NORTE",
        "ESTE",
        "COTA",
        "CAMAS"
    ]

    dim_establecimiento = establecimientos[
        columnas_establecimiento
    ].copy()

    dim_establecimiento = dim_establecimiento.reset_index(
        drop=True
    )

    dim_establecimiento["establecimiento_key"] = (
        dim_establecimiento.index + 1
    )


    # ========================================================
    # DIM_ATENCION
    # ========================================================

    columnas_atencion = [
        "ID_REGISTRO_REL",
        "CODIGO_ANONIMIZADO",
        "NIVEL_EESS",
        "CODIGO_SERV_PRESTACIONAL",
        "SERVICIO_PRESTACIONAL",
        "SEXO"
    ]

    dim_atencion = prestaciones[
        columnas_atencion
    ].drop_duplicates(
        subset=["ID_REGISTRO_REL"]
    ).copy()

    dim_atencion = dim_atencion.reset_index(drop=True)

    dim_atencion["atencion_key"] = (
        dim_atencion.index + 1
    )


    # ========================================================
    # FACT_CONSUMO_MEDICAMENTOS
    # ========================================================

    fact = medicamentos.merge(
        prestaciones,
        on="ID_REGISTRO_REL",
        how="left"
    )


    # --------------------------------------------------------
    # UNIR DIAGNÓSTICO CORRECTAMENTE
    # --------------------------------------------------------

    fact = fact.merge(
        diagnosticos[
            [
                "ID_REGISTRO_REL",
                "CODDIA",
                "TIPO_DIAGNOSTICO"
            ]
        ].drop_duplicates(),
        on=[
            "ID_REGISTRO_REL",
            "CODDIA"
        ],
        how="left"
    )


    # --------------------------------------------------------
    # CREAR FECHA_KEY
    # --------------------------------------------------------

    fact["fecha_key"] = (
        fact["FECHA_ATENCION"]
        .dt.strftime("%Y%m%d")
    )

    fact["fecha_key"] = pd.to_numeric(
        fact["fecha_key"],
        errors="coerce"
    )


    # --------------------------------------------------------
    # MAPEAR MEDICAMENTO
    # --------------------------------------------------------

    fact = fact.merge(
        dim_medicamento[
            [
                "medicamento_key",
                "COD_MEDICAMENTO"
            ]
        ],
        on="COD_MEDICAMENTO",
        how="left"
    )


    # --------------------------------------------------------
    # MAPEAR DIAGNÓSTICO
    # --------------------------------------------------------

    fact = fact.merge(
        dim_diagnostico[
            [
                "diagnostico_key",
                "CODDIA",
                "TIPO_DIAGNOSTICO"
            ]
        ],
        on=[
            "CODDIA",
            "TIPO_DIAGNOSTICO"
        ],
        how="left"
    )


    # --------------------------------------------------------
    # MAPEAR ESTABLECIMIENTO POR UBIGEO
    # --------------------------------------------------------

    fact = fact.merge(
        dim_establecimiento[
            [
                "establecimiento_key",
                "UBIGEO"
            ]
        ],
        left_on="UBIGEO",
        right_on="UBIGEO",
        how="left"
    )


    # --------------------------------------------------------
    # MAPEAR ATENCIÓN
    # --------------------------------------------------------

    fact = fact.merge(
        dim_atencion[
            [
                "atencion_key",
                "ID_REGISTRO_REL"
            ]
        ],
        on="ID_REGISTRO_REL",
        how="left"
    )


    # ========================================================
    # SELECCIONAR COLUMNAS DE LA FACT
    # ========================================================

    fact_final = fact[
        [
            "ID_REGISTRO_REL",
            "fecha_key",
            "medicamento_key",
            "diagnostico_key",
            "establecimiento_key",
            "atencion_key",
            "CANTIDAD_ENTREGADA",
            "VALOR_NETO",
            "DIAS_HOSP",
            "EDAD_DIAS",
            "PESO",
            "ATE_CAPITA"
        ]
    ].copy()


    # ========================================================
    # CONVERTIR CLAVES
    # ========================================================

    fact_final["fecha_key"] = pd.to_numeric(
        fact_final["fecha_key"],
        errors="coerce"
    )

    fact_final["medicamento_key"] = pd.to_numeric(
        fact_final["medicamento_key"],
        errors="coerce"
    )

    fact_final["diagnostico_key"] = pd.to_numeric(
        fact_final["diagnostico_key"],
        errors="coerce"
    )

    fact_final["establecimiento_key"] = pd.to_numeric(
        fact_final["establecimiento_key"],
        errors="coerce"
    )

    fact_final["atencion_key"] = pd.to_numeric(
        fact_final["atencion_key"],
        errors="coerce"
    )


    # ========================================================
    # RESULTADO DE TRANSFORMACIÓN
    # ========================================================

    escribir_log(
        f"DIM_FECHA: {len(fechas)} registros"
    )

    escribir_log(
        f"DIM_MEDICAMENTO: {len(dim_medicamento)} registros"
    )

    escribir_log(
        f"DIM_DIAGNOSTICO: {len(dim_diagnostico)} registros"
    )

    escribir_log(
        f"DIM_ESTABLECIMIENTO: {len(dim_establecimiento)} registros"
    )

    escribir_log(
        f"DIM_ATENCION: {len(dim_atencion)} registros"
    )

    escribir_log(
        f"FACT_CONSUMO_MEDICAMENTOS: {len(fact_final)} registros"
    )


    # ========================================================
    # CARGA AL DATA WAREHOUSE
    # ========================================================

    escribir_log("INICIANDO CARGA AL DATA WAREHOUSE")


    cursor = conexion_dw.cursor()


    # --------------------------------------------------------
    # LIMPIAR TABLAS DEL DW
    # --------------------------------------------------------

    cursor.execute(
        "DELETE FROM FACT_CONSUMO_MEDICAMENTOS"
    )

    cursor.execute(
        "DELETE FROM DIM_ATENCION"
    )

    cursor.execute(
        "DELETE FROM DIM_ESTABLECIMIENTO"
    )

    cursor.execute(
        "DELETE FROM DIM_DIAGNOSTICO"
    )

    cursor.execute(
        "DELETE FROM DIM_MEDICAMENTO"
    )

    cursor.execute(
        "DELETE FROM DIM_FECHA"
    )

    conexion_dw.commit()


    # ========================================================
    # INSERT DIM_FECHA
    # ========================================================

    for _, fila in fechas.iterrows():

        cursor.execute(
            """
            INSERT INTO DIM_FECHA
            (
                fecha_key,
                fecha,
                dia,
                mes,
                nombre_mes,
                trimestre,
                anio
            )
            VALUES (?, ?, ?, ?, ?, ?, ?)
            """,
            int(fila["fecha_key"]),
            fila["fecha"],
            int(fila["dia"]),
            int(fila["mes"]),
            str(fila["nombre_mes"]),
            int(fila["trimestre"]),
            int(fila["anio"])
        )


    # ========================================================
    # INSERT DIM_MEDICAMENTO
    # ========================================================

    for _, fila in dim_medicamento.iterrows():

        cursor.execute(
            """
            INSERT INTO DIM_MEDICAMENTO
            (
                medicamento_key,
                cod_medicamento
            )
            VALUES (?, ?)
            """,
            int(fila["medicamento_key"]),
            str(fila["COD_MEDICAMENTO"])
        )


    # ========================================================
    # INSERT DIM_DIAGNOSTICO
    # ========================================================

    for _, fila in dim_diagnostico.iterrows():

        cursor.execute(
            """
            INSERT INTO DIM_DIAGNOSTICO
            (
                diagnostico_key,
                coddia,
                tipo_diagnostico
            )
            VALUES (?, ?, ?)
            """,
            int(fila["diagnostico_key"]),
            str(fila["CODDIA"]),
            None if pd.isna(
                fila["TIPO_DIAGNOSTICO"]
            ) else str(
                fila["TIPO_DIAGNOSTICO"]
            )
        )


    # ========================================================
    # INSERT DIM_ESTABLECIMIENTO
    # ========================================================

    columnas_insert_eess = [
        "establecimiento_key",
        "CODIGO_UNICO",
        "INSTITUCION",
        "NOMBRE_ESTABLECIMIENTO",
        "CLASIFICACION",
        "TIPO",
        "DEPARTAMENTO",
        "PROVINCIA",
        "DISTRITO",
        "UBIGEO",
        "DIRECCION",
        "CODIGO_DISA",
        "CODIGO_RED",
        "CODIGO_MICRORED",
        "DISA",
        "RED",
        "MICRORED",
        "CODIGO_UE",
        "UNIDAD_EJECUTORA",
        "CATEGORIA",
        "TELEFONO",
        "TIPO_DOC_CATEGORIZACION",
        "NRO_DOC_CATEGORIZACION",
        "HORARIO",
        "INICIO_ACTIVIDAD",
        "DIRECTOR_RESPONSABLE",
        "ESTADO",
        "SITUACION",
        "CONDICION",
        "INSPECCION",
        "NORTE",
        "ESTE",
        "COTA",
        "CAMAS"
    ]


    for _, fila in dim_establecimiento.iterrows():

        valores = []

        for columna in columnas_insert_eess:

            valor = fila[columna]

            if pd.isna(valor):
                valor = None

            elif isinstance(valor, pd.Timestamp):
                valor = valor.to_pydatetime()

            elif hasattr(valor, "item"):
                valor = valor.item()

            valores.append(valor)


        cursor.execute(
            """
            INSERT INTO DIM_ESTABLECIMIENTO
            (
                establecimiento_key,
                codigo_unico,
                institucion,
                nombre_establecimiento,
                clasificacion,
                tipo,
                departamento,
                provincia,
                distrito,
                ubigeo,
                direccion,
                codigo_disa,
                codigo_red,
                codigo_microrred,
                disa,
                red,
                microrred,
                codigo_ue,
                unidad_ejecutora,
                categoria,
                telefono,
                tipo_doc_categorizacion,
                nro_doc_categorizacion,
                horario,
                inicio_actividad,
                director_responsable,
                estado,
                situacion,
                condicion,
                inspeccion,
                norte,
                este,
                cota,
                camas
            )
            VALUES
            (
                ?, ?, ?, ?, ?, ?, ?, ?, ?, ?,
                ?, ?, ?, ?, ?, ?, ?, ?, ?, ?,
                ?, ?, ?, ?, ?, ?, ?, ?, ?, ?,
                ?, ?, ?, ?
            )
            """,
            valores
        )


    # ========================================================
    # INSERT DIM_ATENCION
    # ========================================================

    for _, fila in dim_atencion.iterrows():

        cursor.execute(
            """
            INSERT INTO DIM_ATENCION
            (
                atencion_key,
                id_registro_rel,
                codigo_anonimizado,
                nivel_eess,
                codigo_serv_prestacional,
                servicio_prestacional,
                sexo
            )
            VALUES (?, ?, ?, ?, ?, ?, ?)
            """,
            int(fila["atencion_key"]),
            str(fila["ID_REGISTRO_REL"]),
            None if pd.isna(
                fila["CODIGO_ANONIMIZADO"]
            ) else str(
                fila["CODIGO_ANONIMIZADO"]
            ),
            None if pd.isna(
                fila["NIVEL_EESS"]
            ) else str(
                fila["NIVEL_EESS"]
            ),
            None if pd.isna(
                fila["CODIGO_SERV_PRESTACIONAL"]
            ) else str(
                fila["CODIGO_SERV_PRESTACIONAL"]
            ),
            None if pd.isna(
                fila["SERVICIO_PRESTACIONAL"]
            ) else str(
                fila["SERVICIO_PRESTACIONAL"]
            ),
            None if pd.isna(
                fila["SEXO"]
            ) else str(
                fila["SEXO"]
            )
        )


    # ========================================================
    # INSERT FACT
    # ========================================================

    for _, fila in fact_final.iterrows():

        valores = []

        columnas_fact = [
            "ID_REGISTRO_REL",
            "fecha_key",
            "medicamento_key",
            "diagnostico_key",
            "establecimiento_key",
            "atencion_key",
            "CANTIDAD_ENTREGADA",
            "VALOR_NETO",
            "DIAS_HOSP",
            "EDAD_DIAS",
            "PESO",
            "ATE_CAPITA"
        ]

        for columna in columnas_fact:

            valor = fila[columna]

            if pd.isna(valor):
                valor = None

            elif hasattr(valor, "item"):
                valor = valor.item()

            valores.append(valor)


        cursor.execute(
            """
            INSERT INTO FACT_CONSUMO_MEDICAMENTOS
            (
                id_registro_rel,
                fecha_key,
                medicamento_key,
                diagnostico_key,
                establecimiento_key,
                atencion_key,
                cantidad_entregada,
                valor_neto,
                dias_hosp,
                edad_dias,
                peso,
                ate_capita
            )
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
            """,
            valores
        )


    # ========================================================
    # CONFIRMAR
    # ========================================================

    conexion_dw.commit()

    escribir_log("CARGA COMPLETADA CORRECTAMENTE")


    # ========================================================
    # CERRAR CONEXIONES
    # ========================================================

    cursor.close()

    conexion_fuente.close()

    conexion_dw.close()


    escribir_log("ETL FINALIZADO CORRECTAMENTE")

    print()
    print("======================================")
    print("       ETL FINALIZADO CORRECTAMENTE")
    print("======================================")


except Exception as error:

    escribir_log("ERROR DURANTE EL ETL")

    escribir_log(str(error))

    print()
    print("======================================")
    print("          ERROR DURANTE EL ETL")
    print("======================================")
    print(error)