*&---------------------------------------------------------------------*
*& Report ZCONSULTA_MERITOS
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*
REPORT zconsulta_meritos.

TABLES: zhrp_asis_lis,
        zmeritos_salida,
        hrp1000.
"ICON
TYPE-POOLS slis.

"DATA PARA MANEJO DE VALORES PARA DNI
DATA: lv_dni     TYPE zcds_union_meritos_m03-dni,
      struc_dni  TYPE  zst_dni_list1,
      struc_dni1 TYPE STANDARD TABLE OF zst_dni_list1.

"DATA PARA LLAMADA AL SERVICIO
DATA input TYPE zfp2030meritos1.
DATA(get_meritos) = NEW zcl_docs_meritos( ).

"DATA ALV GRID
DATA gt_fieldcat TYPE slis_t_fieldcat_alv.
DATA ls_fieldcat TYPE slis_fieldcat_alv.
DATA gs_layout TYPE slis_layout_alv.
DATA gt_events TYPE slis_t_event.

"DATA PARA ESTRUCTURA PROFUNDA DE MERITOS
TYPES: BEGIN OF ty_meritos_simple,
         dni              TYPE prdni,
         nombre           TYPE pad_vorna,
         apellidos        TYPE pad_cname,
         codmerito        TYPE hrobjid,
         codclasificacion TYPE p04p_ap_dmand,
         fechavalidacion  TYPE char10,
         documento        TYPE char6,
       END OF ty_meritos_simple.

DATA: lt_meritos_simple TYPE STANDARD TABLE OF ty_meritos_simple,
      ls_meritos_simple TYPE ty_meritos_simple.

"RECUPERAR DATOS A LA PANTALLA DE SELECCIÓN
DATA: gv_dni   TYPE zhrp_asis_lis-dni,
      gv_codme TYPE zmeritos_salida-codmerito.

"--------------- SELECTION-SCREEN -----------------------------*
SELECTION-SCREEN BEGIN OF BLOCK b01 WITH FRAME TITLE TEXT-001.
  SELECTION-SCREEN SKIP.

  SELECTION-SCREEN BEGIN OF BLOCK b02 WITH FRAME TITLE TEXT-002.
    SELECT-OPTIONS so_dni FOR zhrp_asis_lis-dni NO INTERVALS MODIF ID dni.
    SELECTION-SCREEN COMMENT /3(70) TEXT-003.
  SELECTION-SCREEN END OF BLOCK b02.

  SELECTION-SCREEN BEGIN OF BLOCK b03 WITH FRAME TITLE TEXT-004.
    PARAMETERS:
      p_fdesde TYPE sydatum OBLIGATORY DEFAULT '18000101',
      p_fhasta TYPE sydatum OBLIGATORY DEFAULT '99991231'.
    SELECTION-SCREEN COMMENT /3(70) TEXT-005.
  SELECTION-SCREEN END OF BLOCK b03.

  SELECTION-SCREEN BEGIN OF BLOCK b04 WITH FRAME TITLE TEXT-006.
    PARAMETERS:
      p_codme TYPE zmeritos_salida-codmerito MATCHCODE OBJECT zab_codmerito,
      p_codcl TYPE hrp1000-short MATCHCODE OBJECT zab_codclasif.
    SELECTION-SCREEN COMMENT /3(70) TEXT-007.
  SELECTION-SCREEN END OF BLOCK b04.

SELECTION-SCREEN END OF BLOCK b01.

START-OF-SELECTION.

  "-------------- ASIGNACIÓN DE CAMPOS DEL WEB SERVICE ------------
  LOOP AT so_dni INTO DATA(wa_sodni).
    struc_dni-dni = wa_sodni-low.
    APPEND struc_dni TO struc_dni1.
  ENDLOOP.
  input-consultameritosrequest-dnilist-item = struc_dni1.

  GET TIME STAMP FIELD DATA(ts).
  input-auditoriarequest-dirip = '10.12.203.20'.
  input-auditoriarequest-marcatiempo =  ts.
  input-consultameritosrequest-codmerito = p_codme.
  input-consultameritosrequest-codclasificacion = p_codcl.
  input-consultameritosrequest-fechahasta = p_fhasta.
  input-consultameritosrequest-fechadesde = p_fdesde.

  "---------------- LLAMADA AL SERVICIO ------------------------------
  TRY.
      DATA(meritos) = NEW zco_zmeritos( logical_port_name = 'AINOA' ).
      meritos->zf_p2030meritos(
        EXPORTING
          input  = input
        IMPORTING
          output = DATA(lt)
      ).

    CATCH cx_ai_system_fault INTO DATA(lx_ex).    "CAPTURA DE ERROR EN COMUNICACIÓN
      DATA(cod_error_fault_system) = lx_ex->get_text( ).

      "INDICAMOS EL ERROR EN UN POPUP
      CALL FUNCTION 'POPUP_TO_DISPLAY_TEXT'
        EXPORTING
          titel     = 'Consulta Méritos'
          textline1 = cod_error_fault_system.

    CATCH zcx_zf_p2030meritos_exception1 INTO DATA(lx_ex2). "CAPTURA DE ERROR DEL SERVICIO
      DATA(error) = lx_ex2->zf_p2030meritos_exception-descripcion.
      DATA(cod_error) = lx_ex2->zf_p2030meritos_exception-codigo.

      CALL FUNCTION 'POPUP_TO_DISPLAY_TEXT'
        EXPORTING
          titel     = 'Consulta Méritos'
          textline1 = error
          textline2 = cod_error.

      CALL TRANSACTION 'ZCONSULTA_MERITOS'. "LUEGO DEL MENSAJE DE ERROR, VOLVEMOS A LA PANTALLA DE SELECCIÓN
  ENDTRY.

  "-------- ESTRUCTURA APLANADA DE MERITOS PARA ALV ------------------
  LOOP AT lt-consultameritosresponse-item ASSIGNING FIELD-SYMBOL(<fs_lt>).
    CLEAR: ls_meritos_simple.

    "ASIGNAMOS DNI, NOMBRE Y APELLIDO
    ls_meritos_simple-dni = <fs_lt>-dni.
    ls_meritos_simple-nombre = <fs_lt>-nombre.
    ls_meritos_simple-apellidos = <fs_lt>-apellidos.

    "LOOP A LA LISTA DE MÉRITOS
    LOOP AT <fs_lt>-listadomeritos-item ASSIGNING FIELD-SYMBOL(<fs_merito>).
      CLEAR: ls_meritos_simple-codmerito, ls_meritos_simple-codclasificacion,
             ls_meritos_simple-fechavalidacion, ls_meritos_simple-documento.

      "ASIGNAMOS LOS VALORES DE CODMERITO, CODCLASIFICACION, FECHAVALIDACION, DOCUMENTO
      ls_meritos_simple-codmerito = <fs_merito>-codmerito.
      ls_meritos_simple-codclasificacion = <fs_merito>-codclasificacion.
      ls_meritos_simple-fechavalidacion = <fs_merito>-fechavalidacion.
      IF p_codme IS INITIAL.
        ls_meritos_simple-documento = '@13@'.
      ELSE.
        ls_meritos_simple-documento = '@0Y@'.
      ENDIF.
      APPEND ls_meritos_simple TO lt_meritos_simple.

    ENDLOOP.
  ENDLOOP.
  "---------------------------------------------------------------------

  PERFORM build_alv_grid. "CONSTRUIR ALV GRID ---------
  PERFORM show_alv_grid. "MOSTRAR INFO ----------------
  PERFORM add_events. "EVENTOS ------------------------

  INCLUDE z_alv_grid.
  INCLUDE z_build_alv_grid.
  INCLUDE z_get_info.
  INCLUDE z_add_events.
