*----------------------------------------------------------------------*
***INCLUDE Z_ADD_EVENTS.
*----------------------------------------------------------------------*
*&---------------------------------------------------------------------*
*& Form add_events
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM add_events.

  DATA ls_events TYPE slis_alv_event.

  ls_events-name = 'TOP_OF_PAGE'. "NOMBRE DEL EVENTO
  ls_events-form = 'TOP_OF_PAGE'.
  APPEND ls_events TO gt_events.

ENDFORM.
FORM top_of_page.

  DATA: lt_list_commentary TYPE  slis_t_listheader,
        ls_list_commentary TYPE  slis_listheader.

  ls_list_commentary-typ = 'H'.
  ls_list_commentary-info = 'Información del servicio'.
  APPEND ls_list_commentary TO lt_list_commentary.

  ls_list_commentary-typ = 'S'.
  CONCATENATE 'Usuario: ' sy-uname INTO ls_list_commentary-info RESPECTING BLANKS.
  APPEND ls_list_commentary TO lt_list_commentary.

  ls_list_commentary-typ = 'S'.
  CONCATENATE 'Hora: ' sy-uzeit INTO ls_list_commentary-info.
  APPEND ls_list_commentary TO lt_list_commentary.

  CALL FUNCTION 'REUSE_ALV_COMMENTARY_WRITE'
    EXPORTING
      it_list_commentary = lt_list_commentary
*     I_LOGO             =
*     I_END_OF_LIST_GRID =
*     I_ALV_FORM         =
    .

ENDFORM.
