*----------------------------------------------------------------------*
***INCLUDE Z_BUILD_ALV_GRID.
*----------------------------------------------------------------------*
*&---------------------------------------------------------------------*
*& Form build_alv_grid
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM build_alv_grid .

  CLEAR ls_fieldcat.
  ls_fieldcat-Fieldname = 'DNI'.
  ls_fieldcat-seltext_s = 'DNI'.
  APPEND ls_fieldcat TO gt_fieldcat.

  CLEAR ls_fieldcat.
  ls_fieldcat-fieldname = 'NOMBRE'.
  ls_fieldcat-seltext_l = 'Nombre'.
  APPEND ls_fieldcat TO gt_fieldcat.
  CLEAR ls_fieldcat.

  CLEAR ls_fieldcat.
  ls_fieldcat-Fieldname = 'APELLIDOS'.
  ls_fieldcat-seltext_s = 'Apellidos'.
  APPEND ls_fieldcat TO gt_fieldcat.

  CLEAR ls_fieldcat.
  ls_fieldcat-fieldname = 'CODMERITO'.
  ls_fieldcat-seltext_l = 'Código Mérito'.
  APPEND ls_fieldcat TO gt_fieldcat.
  CLEAR ls_fieldcat.

  CLEAR ls_fieldcat.
  ls_fieldcat-fieldname = 'CODCLASIFICACION'.
  ls_fieldcat-seltext_l = 'Código Clasificación'.
  APPEND ls_fieldcat TO gt_fieldcat.
  CLEAR ls_fieldcat.

  CLEAR ls_fieldcat.
  ls_fieldcat-Fieldname = 'FECHAVALIDACION'.
  ls_fieldcat-seltext_l = 'Fecha Validación'.
  APPEND ls_fieldcat TO gt_fieldcat.

  CLEAR ls_fieldcat.
  ls_fieldcat-fieldname = 'DOCUMENTO'.
  ls_fieldcat-seltext_l = 'Documento'.
  ls_fieldcat-hotspot = abap_true.
  ls_fieldcat-icon = abap_true. "COLUMNA DE TIPO ICONO
  APPEND ls_fieldcat TO gt_fieldcat.

  "--------- LAYOUT -----------------
  gs_layout-zebra = abap_true.
  gs_layout-cell_merge = abap_true.
  gs_layout-colwidth_optimize = abap_true.

ENDFORM.

FORM user_command  USING pv_ucomm LIKE sy-ucomm
                  rs_selfield TYPE slis_selfield.

  DATA: lv_doc_xstring  TYPE xstring,
        lv_longitud_bin TYPE i,
        lv_doc_binary   TYPE rmps_t_1024,
        archivobject    TYPE rmps_t_1024,
        lv_url          TYPE string,
        xstring         TYPE xstring,
        base64_string   TYPE string,
        path_file       TYPE string VALUE 'hola.pdf'.

  CASE rs_selfield-fieldname.
    WHEN 'DOCUMENTO'.

      "------- OBTENER EL MÉRITO SEGUN LA FILA SELECCIONADA ---------------
      READ TABLE lt-consultameritosresponse-item INTO DATA(ls_lt) INDEX 1.
      IF sy-subrc = 0.

        READ TABLE ls_lt-listadomeritos-item INTO DATA(ls_doc) INDEX rs_selfield-tabindex.
        IF sy-subrc = 0.

          "------- ASIGNACIÓN DE MÉRITO SELECCIONADO ------------------------
          IF p_codme IS INITIAL.
            gv_dni = ls_lt-dni. "DNI SELECCIONADO
            gv_codme = ls_doc-codmerito. "MÉRITO SELECCIONADO

            CLEAR so_dni.
            APPEND VALUE #( sign = 'I' option = 'EQ' low = gv_dni ) TO so_dni.

            SUBMIT zconsulta_meritos
            WITH p_codme = gv_codme
            WITH so_dni IN so_dni
            AND RETURN.
          ELSE.

            "--------- CONVERTIMOS DE BASE64 A XSTRING ------------------------
            lv_doc_xstring = cl_http_utility=>if_http_utility~decode_x_base64( ls_doc-documento ).

            "--------- CONVERTIMOS DE XSTRING A BINARIO ------------------------
            CALL FUNCTION 'SCMS_XSTRING_TO_BINARY'
              EXPORTING
                buffer        = lv_doc_xstring
              IMPORTING
                output_length = lv_longitud_bin
              TABLES
                binary_tab    = lv_doc_binary.

            IF sy-subrc = 0.

              "--------- CONVERTIMOS DE BINARIO A TEXTO PLANO ------------------------
              CALL FUNCTION 'SCMS_BINARY_TO_FTEXT'
                EXPORTING
                  input_length  = lv_longitud_bin
                IMPORTING
                  output_length = lv_longitud_bin
                TABLES
                  binary_tab    = lv_doc_binary
                  ftext_tab     = archivobject
                EXCEPTIONS
                  failed        = 1
                  OTHERS        = 2.

              IF sy-subrc = 0.

                "------ CONVERSIÓN, APERTURA, TRANSFERENCIA Y CIERRE DEL ARCHIVO PDF ------
                OPEN DATASET path_file FOR OUTPUT IN BINARY MODE.
                IF sy-subrc = 0.
                  TRANSFER lv_doc_xstring TO path_file.
                  CLOSE DATASET path_file.

                  "--------- VIZUALIZACIÓN DEL PDF ------------------------
                  CALL FUNCTION '/IPRO/VIEW_PDF'
                    EXPORTING
                      iv_title   = 'Visualización del documento'
                      iv_content = lv_doc_xstring.

                ELSE.
                  MESSAGE 'Error al abrir el archivo' TYPE 'E'.
                ENDIF.

              ELSE.
                MESSAGE 'Error en la conversión de binario a texto' TYPE 'E'.
              ENDIF.

            ELSE.
              MESSAGE 'Error en la conversión de xstring a binario' TYPE 'E'.
            ENDIF.

          ENDIF.  "ELSE p_codme IS INITIAL

        ELSE.
          MESSAGE 'Error al leer los méritos' TYPE 'E'.
        ENDIF.

      ELSE.
        MESSAGE 'Error al leer los datos de respuesta' TYPE 'E'.
      ENDIF.

  ENDCASE.

ENDFORM.

FORM set_pf_status USING rt_extab TYPE slis_t_extab.

  SET PF-STATUS 'STATUS_MERITOS'.

ENDFORM.
