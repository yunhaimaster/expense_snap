// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class SEs extends S {
  SEs([String locale = 'es']) : super(locale);

  @override
  String get appTitle => 'Expense Snap';

  @override
  String get common_save => 'Guardar';

  @override
  String get common_cancel => 'Cancelar';

  @override
  String get common_delete => 'Eliminar';

  @override
  String get common_edit => 'Editar';

  @override
  String get common_retry => 'Reintentar';

  @override
  String get common_confirm => 'Confirmar';

  @override
  String get common_back => 'Volver';

  @override
  String get common_skip => 'Omitir';

  @override
  String get common_next => 'Siguiente';

  @override
  String get common_done => 'Hecho';

  @override
  String get common_close => 'Cerrar';

  @override
  String get common_restore => 'Restaurar';

  @override
  String get common_clear => 'Limpiar';

  @override
  String get common_share => 'Compartir';

  @override
  String get common_loading => 'Cargando...';

  @override
  String get common_saving => 'Guardando...';

  @override
  String get common_processing => 'Procesando...';

  @override
  String get nav_home => 'Inicio';

  @override
  String get nav_export => 'Exportar';

  @override
  String get nav_settings => 'Ajustes';

  @override
  String get home_addExpense => 'Agregar gasto';

  @override
  String get home_deleteSuccess => 'Gasto eliminado';

  @override
  String home_deleteFailed(String message) {
    return 'Error al eliminar: $message';
  }

  @override
  String get home_undo => 'Deshacer';

  @override
  String get showcase_addExpenseTitle => 'Agregar gasto';

  @override
  String get showcase_addExpenseDesc =>
      'Toca aquí para tomar una foto y registrar tu gasto';

  @override
  String get showcase_swipeDeleteTitle => 'Deslizar para eliminar';

  @override
  String get showcase_swipeDeleteDesc =>
      'Desliza hacia la izquierda para eliminar un gasto';

  @override
  String get showcase_exportTitle => 'Exportar informe';

  @override
  String get showcase_exportDesc => 'Toca aquí para exportar Excel y recibos';

  @override
  String get addExpense_title => 'Agregar gasto';

  @override
  String get addExpense_receiptImage => 'Imagen del recibo';

  @override
  String get addExpense_camera => 'Cámara';

  @override
  String get addExpense_gallery => 'Galería';

  @override
  String get addExpense_amount => 'Monto';

  @override
  String get addExpense_description => 'Descripción';

  @override
  String get addExpense_descriptionHint => 'Ingrese una descripción...';

  @override
  String get addExpense_date => 'Fecha';

  @override
  String get addExpense_currency => 'Moneda';

  @override
  String get addExpense_exchangeRate => 'Tipo de cambio';

  @override
  String get addExpense_manualInput => 'Entrada manual';

  @override
  String get addExpense_ocrProcessing => 'Reconociendo recibo...';

  @override
  String get addExpense_ocrSuccess => 'Contenido del recibo reconocido';

  @override
  String get addExpense_ocrSuccessVerify =>
      'Contenido del recibo reconocido, por favor verifique';

  @override
  String get addExpense_success => 'Gasto agregado';

  @override
  String get addExpense_invalidAmount => 'Por favor ingrese un monto válido';

  @override
  String get addExpense_invalidExchangeRate =>
      'El tipo de cambio debe ser mayor que 0';

  @override
  String get expenseDetail_title => 'Detalles del gasto';

  @override
  String get expenseDetail_editTitle => 'Editar gasto';

  @override
  String get expenseDetail_amount => 'Monto';

  @override
  String get expenseDetail_hkdAmount => 'Monto en HKD';

  @override
  String get expenseDetail_exchangeRate => 'Tipo de cambio';

  @override
  String get expenseDetail_description => 'Descripción';

  @override
  String get expenseDetail_descriptionRequired =>
      'Por favor ingrese una descripción';

  @override
  String get expenseDetail_date => 'Fecha';

  @override
  String get expenseDetail_createdAt => 'Fecha de creación';

  @override
  String get expenseDetail_replaceImage => 'Reemplazar imagen';

  @override
  String get expenseDetail_imageLoadFailed => 'Error al cargar la imagen';

  @override
  String get expenseDetail_noReceipt => 'Sin imagen de recibo';

  @override
  String get expenseDetail_cancelEdit => 'Cancelar edición';

  @override
  String get expenseDetail_saved => 'Guardado';

  @override
  String expenseDetail_saveFailed(String message) {
    return 'Error al guardar: $message';
  }

  @override
  String get expenseDetail_deleted => 'Eliminado';

  @override
  String expenseDetail_deleteFailed(String message) {
    return 'Error al eliminar: $message';
  }

  @override
  String get expenseDetail_confirmDelete => 'Confirmar eliminación';

  @override
  String get expenseDetail_confirmDeleteMessage =>
      '¿Está seguro de que desea eliminar este gasto?\nPuede restaurarlo desde Elementos eliminados.';

  @override
  String get expenseDetail_expenseNotFound => 'Gasto no encontrado';

  @override
  String get expenseDetail_imageReplaceSuccess => 'Imagen reemplazada';

  @override
  String expenseDetail_imageReplaceFailed(String message) {
    return 'Error al reemplazar imagen: $message';
  }

  @override
  String get expenseDetail_selectFromGallery => 'Seleccionar de la galería';

  @override
  String get rateSource_auto => 'Tasa en vivo';

  @override
  String get rateSource_offline => 'Tasa en caché';

  @override
  String get rateSource_default => 'Tasa predeterminada';

  @override
  String get rateSource_manual => 'Entrada manual';

  @override
  String get rateSource_auto_short => 'En vivo';

  @override
  String get rateSource_offline_short => 'Caché';

  @override
  String get rateSource_default_short => 'Predeterminado';

  @override
  String get rateSource_manual_short => 'Manual';

  @override
  String get monthSummary_totalExpense => 'Gasto total';

  @override
  String get monthSummary_count => 'Cantidad';

  @override
  String get monthSummary_countSuffix => '';

  @override
  String get monthSummary_previousMonth => 'Mes anterior';

  @override
  String get monthSummary_nextMonth => 'Mes siguiente';

  @override
  String monthSummary_semanticLabel(String month, String amount, int count) {
    return 'Resumen de $month. Gasto total: HKD $amount. $count gastos.';
  }

  @override
  String get monthSummary_isLatestMonth => 'Ya está en el mes más reciente';

  @override
  String get monthSummary_mixedCurrencies => 'Múltiples monedas';

  @override
  String get export_title => 'Exportar informe';

  @override
  String get export_preview => 'Vista previa';

  @override
  String get export_expenseCount => 'Cantidad de gastos';

  @override
  String get export_totalHkd => 'Total en HKD';

  @override
  String get export_receiptCount => 'Imágenes de recibos';

  @override
  String export_countUnit(int count) {
    return '$count';
  }

  @override
  String export_imageUnit(int count) {
    return '$count';
  }

  @override
  String get export_excelWithReceipts => 'Exportar Excel + Recibos';

  @override
  String get export_noData => 'Sin datos';

  @override
  String export_noDataMessage(int year, int month) {
    return 'No hay gastos registrados en $year/$month';
  }

  @override
  String export_yearMonth(int year, int month) {
    return '$year/$month';
  }

  @override
  String get export_hint =>
      'El Excel exportado contiene detalles completos de gastos';

  @override
  String get export_packing => 'Empaquetando...';

  @override
  String get export_generatingExcel => 'Generando Excel...';

  @override
  String get export_packingReceipts => 'Empaquetando imágenes de recibos...';

  @override
  String get export_compressing => 'Comprimiendo...';

  @override
  String get export_preparingShare => 'Preparando para compartir...';

  @override
  String export_success(String size) {
    return 'Exportación exitosa ($size)';
  }

  @override
  String export_failed(String message) {
    return 'Error en la exportación: $message';
  }

  @override
  String export_sheetName(int year, int month) {
    return 'Informe de gastos $year/$month';
  }

  @override
  String get export_shareSubject => 'Informe de Expense Snap';

  @override
  String get export_headerIndex => 'No.';

  @override
  String get export_headerDate => 'Fecha';

  @override
  String get export_headerDescription => 'Descripción';

  @override
  String get export_headerOriginalAmount => 'Monto original';

  @override
  String get export_headerOriginalCurrency => 'Moneda';

  @override
  String get export_headerExchangeRate => 'Tipo de cambio';

  @override
  String get export_headerRateSource => 'Fuente de tasa';

  @override
  String export_headerConvertedAmount(String currency) {
    return 'Monto en $currency';
  }

  @override
  String get export_headerReceiptFile => 'Recibo';

  @override
  String get export_headerTotal => 'Total';

  @override
  String get export_rateSourceAuto => 'Automático';

  @override
  String get export_rateSourceOffline => 'Caché sin conexión';

  @override
  String get export_rateSourceDefault => 'Predeterminado';

  @override
  String get export_rateSourceManual => 'Manual';

  @override
  String export_fileName(int year, String month) {
    return 'Informe_gastos_${year}_$month';
  }

  @override
  String get settings_title => 'Ajustes';

  @override
  String get settings_general => 'General';

  @override
  String get settings_userName => 'Nombre de usuario';

  @override
  String get settings_userNameHint => 'Usado para el título del informe';

  @override
  String get settings_language => 'Idioma';

  @override
  String get settings_theme => 'Tema';

  @override
  String get settings_themeLight => 'Claro';

  @override
  String get settings_themeDark => 'Oscuro';

  @override
  String get settings_themeSystem => 'Sistema';

  @override
  String get settings_data => 'Gestión de datos';

  @override
  String get settings_backup => 'Copia de seguridad en la nube';

  @override
  String get settings_backupDesc => 'Copia de seguridad en Google Drive';

  @override
  String get settings_restore => 'Restaurar copia';

  @override
  String get settings_restoreDesc => 'Restaurar desde Google Drive';

  @override
  String get settings_deletedItems => 'Elementos eliminados';

  @override
  String get settings_deletedItemsDesc => 'Ver o restaurar gastos eliminados';

  @override
  String get settings_clearCache => 'Limpiar archivos temporales';

  @override
  String get settings_about => 'Acerca de';

  @override
  String get settings_version => 'Versión';

  @override
  String get settings_privacyPolicy => 'Política de privacidad';

  @override
  String get settings_termsOfService => 'Términos de servicio';

  @override
  String get settings_feedback => 'Comentarios';

  @override
  String get legal_privacyContent =>
      'Política de privacidad\n\nÚltima actualización: Enero 2026\n\n1. Recopilación de datos\nSolo recopilamos los datos que usted ingresa voluntariamente, incluyendo registros de gastos, imágenes de recibos y configuraciones personales.\n\n2. Almacenamiento de datos\nTodos los datos se almacenan localmente en su dispositivo. Si elige usar la función de copia de seguridad en la nube, los datos se sincronizarán con su cuenta de Google Drive.\n\n3. Uso de datos\nNo utilizamos sus datos para publicidad ni los compartimos con terceros.\n\n4. Eliminación de datos\nPuede eliminar todos los datos en la aplicación en cualquier momento. Los elementos eliminados se mantienen durante 30 días antes de su eliminación permanente.\n\n5. Contacto\nPara cualquier pregunta relacionada con la privacidad, contáctenos a través de la función de comentarios en la aplicación.';

  @override
  String get legal_termsContent =>
      'Términos de servicio\n\nÚltima actualización: Enero 2026\n\n1. Descripción del servicio\nExpense Snap es una aplicación de seguimiento de gastos personales que le ayuda a registrar y gestionar sus gastos diarios.\n\n2. Condiciones de uso\nAl usar esta aplicación, acepta cumplir con estos términos.\n\n3. Limitación de responsabilidad\nEsta aplicación se proporciona \"tal cual\". No somos responsables por la pérdida de datos ni por daños indirectos.\n\n4. Propiedad intelectual\nTodo el contenido y las funciones de la aplicación están protegidos por derechos de autor.\n\n5. Modificación de términos\nNos reservamos el derecho de modificar estos términos en cualquier momento. El uso continuado indica la aceptación de los términos modificados.';

  @override
  String get settings_signInGoogle => 'Iniciar sesión con Google';

  @override
  String get settings_signOutGoogle => 'Cerrar sesión';

  @override
  String settings_signedInAs(String email) {
    return 'Conectado como: $email';
  }

  @override
  String get settings_backupSuccess => 'Copia de seguridad exitosa';

  @override
  String settings_backupFailed(String message) {
    return 'Error en la copia de seguridad: $message';
  }

  @override
  String get settings_restoreSuccess => 'Restauración exitosa';

  @override
  String settings_restoreFailed(String message) {
    return 'Error en la restauración: $message';
  }

  @override
  String get settings_cacheCleared => 'Caché limpiado';

  @override
  String get settings_noBackupFound => 'No se encontró copia de seguridad';

  @override
  String get settings_confirmRestore => 'Confirmar restauración';

  @override
  String get settings_confirmRestoreMessage =>
      'La restauración sobrescribirá los datos actuales. ¿Continuar?';

  @override
  String settings_lastBackup(String date) {
    return 'Última copia: $date';
  }

  @override
  String get deletedItems_title => 'Elementos eliminados';

  @override
  String get deletedItems_clearAll => 'Limpiar todo';

  @override
  String deletedItems_daysRemaining(int days) {
    return '$days días hasta eliminación automática';
  }

  @override
  String get deletedItems_soonDeleted => 'Se eliminará pronto';

  @override
  String get deletedItems_restored => 'Restaurado';

  @override
  String deletedItems_restoreFailed(String message) {
    return 'Error al restaurar: $message';
  }

  @override
  String get deletedItems_permanentDelete => 'Eliminar permanentemente';

  @override
  String get deletedItems_permanentDeleteConfirm =>
      'Esta acción no se puede deshacer. ¿Eliminar permanentemente?';

  @override
  String get deletedItems_permanentDeleted => 'Eliminado permanentemente';

  @override
  String deletedItems_permanentDeleteFailed(String message) {
    return 'Error al eliminar: $message';
  }

  @override
  String get deletedItems_clearAllTitle => 'Limpiar todo';

  @override
  String deletedItems_clearAllConfirm(int count) {
    return '¿Eliminar permanentemente los $count elementos?\nEsta acción no se puede deshacer.';
  }

  @override
  String get deletedItems_clearAllButton => 'Eliminar todo';

  @override
  String deletedItems_clearedCount(int count) {
    return '$count elementos eliminados';
  }

  @override
  String deletedItems_loadFailed(String message) {
    return 'Error al cargar: $message';
  }

  @override
  String get onboarding_skip => 'Omitir';

  @override
  String get onboarding_next => 'Siguiente';

  @override
  String get onboarding_start => 'Comenzar';

  @override
  String get onboarding_page1Title => 'Captura tus recibos';

  @override
  String get onboarding_page1Desc =>
      'Toma fotos de recibos al instante\nNunca más pierdas un recibo';

  @override
  String get onboarding_page2Title => 'Soporte multimoneda';

  @override
  String get onboarding_page2Desc =>
      'Compatible con HKD, CNY, USD\nObtiene tipos de cambio en tiempo real';

  @override
  String get onboarding_page3Title => 'Exportación con un clic';

  @override
  String get onboarding_page3Desc =>
      'Exporta Excel + imágenes de recibos\nInformes de gastos fáciles';

  @override
  String get onboarding_selectCurrencyTitle =>
      'Seleccionar moneda de liquidación';

  @override
  String get onboarding_selectCurrencyDesc =>
      'Los gastos se convertirán automáticamente a esta moneda';

  @override
  String get onboarding_nameLabel => 'Su nombre (Opcional)';

  @override
  String get onboarding_nameHint => 'Usado para el título del informe';

  @override
  String get onboarding_nameTooLong =>
      'El nombre no puede exceder 50 caracteres';

  @override
  String get connectivity_offlineMode =>
      'Modo sin conexión - Los tipos de cambio pueden estar desactualizados';

  @override
  String get dialog_duplicateTitle => 'Posible duplicado';

  @override
  String get dialog_duplicateMessage => 'Se encontró un gasto similar:';

  @override
  String get dialog_duplicateConfirm => '¿Continuar agregando?';

  @override
  String get dialog_duplicateContinue => 'Agregar de todos modos';

  @override
  String get dialog_largeAmountTitle => 'Monto grande';

  @override
  String get dialog_largeAmountMessage => 'Está registrando un gasto grande:';

  @override
  String get dialog_largeAmountConfirm => '¿Es correcto el monto?';

  @override
  String get dialog_largeAmountBack => 'Volver';

  @override
  String get dialog_largeAmountOk => 'Confirmar';

  @override
  String get dialog_monthEndTitle => 'Recordatorio de fin de mes';

  @override
  String get dialog_monthEndMessage => '¡El mes está por terminar!';

  @override
  String dialog_monthEndExpenseCount(int count) {
    return 'Tiene $count gastos este mes';
  }

  @override
  String get dialog_monthEndSuggestion =>
      'Considere exportar su informe de gastos.';

  @override
  String get dialog_later => 'Más tarde';

  @override
  String get dialog_goExport => 'Exportar ahora';

  @override
  String get emptyState_noExpenses => 'Sin gastos';

  @override
  String get emptyState_noExpensesHint =>
      'Toque el botón de abajo para agregar su primer gasto';

  @override
  String get emptyState_noDeletedItems => 'Sin elementos eliminados';

  @override
  String get emptyState_noDeletedItemsHint =>
      'Los gastos eliminados se mantienen durante 30 días';

  @override
  String get emptyState_error => 'Error al cargar';

  @override
  String get emptyState_offline => 'Sin conexión a Internet';

  @override
  String get emptyState_offlineHint =>
      'Por favor verifique su configuración de red';

  @override
  String get emptyState_exportSuccess => 'Exportación exitosa';

  @override
  String get emptyState_exportSuccessHint => 'El archivo está listo';

  @override
  String get excel_header_index => 'No.';

  @override
  String get excel_header_date => 'Fecha';

  @override
  String get excel_header_description => 'Descripción';

  @override
  String get excel_header_originalAmount => 'Monto original';

  @override
  String get excel_header_originalCurrency => 'Moneda';

  @override
  String get excel_header_exchangeRate => 'Tipo de cambio';

  @override
  String get excel_header_rateSource => 'Fuente de tasa';

  @override
  String get excel_header_hkdAmount => 'Monto en HKD';

  @override
  String get excel_header_receiptFile => 'Archivo de recibo';

  @override
  String get excel_total => 'Total';

  @override
  String excel_sheetName(int year, int month) {
    return 'Gastos_${year}_$month';
  }

  @override
  String excel_fileName(int year, String month) {
    return 'Gastos_${year}_$month';
  }

  @override
  String get excel_shareSubject => 'Informe de Expense Snap';

  @override
  String get excel_rateSourceAuto => 'Automático';

  @override
  String get excel_rateSourceOffline => 'Caché';

  @override
  String get excel_rateSourceDefault => 'Predeterminado';

  @override
  String get excel_rateSourceManual => 'Manual';

  @override
  String get error_unknown => 'Ocurrió un error desconocido';

  @override
  String get error_networkError => 'Error de conexión de red';

  @override
  String get error_serverError => 'Error del servidor';

  @override
  String get error_storageError => 'Error de almacenamiento';

  @override
  String get error_permissionDenied => 'Permiso denegado';

  @override
  String get error_fileNotFound => 'Archivo no encontrado';

  @override
  String get error_invalidData => 'Formato de datos no válido';

  @override
  String get error_exportNoData => 'No hay datos para exportar';

  @override
  String get error_invalidMonth => 'El mes debe estar entre 1 y 12';

  @override
  String get error_invalidYear => 'El año debe estar entre 2000 y 2100';

  @override
  String get error_excelGenerationFailed => 'Error al generar archivo Excel';

  @override
  String get error_zipFailed => 'Error al comprimir archivo';

  @override
  String get error_shareFailed => 'Error al compartir';

  @override
  String get error_cleanupFailed => 'Error al limpiar archivos temporales';

  @override
  String get format_date => 'yyyy/MM/dd';

  @override
  String get format_dateTime => 'yyyy/MM/dd HH:mm';

  @override
  String get format_month => 'MMM yyyy';

  @override
  String get format_currency => '#,##0.00';

  @override
  String get currency_HKD => 'HKD';

  @override
  String get currency_CNY => 'CNY';

  @override
  String get currency_USD => 'USD';

  @override
  String get currency_EUR => 'Euro';

  @override
  String get currency_GBP => 'Libra esterlina';

  @override
  String get currency_JPY => 'Yen japonés';

  @override
  String get currency_TWD => 'Dólar taiwanés';

  @override
  String get currency_KRW => 'Won surcoreano';

  @override
  String get currency_SGD => 'Dólar singapurense';

  @override
  String get currency_AUD => 'Dólar australiano';

  @override
  String get datePicker_selectDate => 'Seleccionar fecha';

  @override
  String get datePicker_selectMonth => 'Seleccionar mes';

  @override
  String get settings_profile => 'Perfil';

  @override
  String get settings_appearance => 'Apariencia';

  @override
  String get settings_reduceMotion => 'Reducir movimiento';

  @override
  String get settings_reduceMotionDesc =>
      'Reduce las animaciones para sensibilidad al movimiento';

  @override
  String get settings_storageUsage => 'Uso de almacenamiento';

  @override
  String get settings_clearCacheDesc =>
      'Liberar espacio de caché de exportación y copia de seguridad';

  @override
  String get settings_cloudBackup => 'Copia de seguridad en la nube';

  @override
  String get settings_googleDrive => 'Google Drive';

  @override
  String get settings_lastBackupTime => 'Última copia';

  @override
  String get settings_backupNow => 'Hacer copia ahora';

  @override
  String get settings_backupNowDesc =>
      'Respaldar base de datos y recibos en Google Drive';

  @override
  String get settings_restoreBackupTitle => 'Restaurar copia';

  @override
  String get settings_restoreBackupDesc => 'Restaurar desde Google Drive';

  @override
  String get settings_selectBackup => 'Seleccionar copia';

  @override
  String get settings_connect => 'Conectar';

  @override
  String get settings_disconnect => 'Desconectar';

  @override
  String get settings_connected => 'Conectado';

  @override
  String get settings_notConnected => 'No conectado';

  @override
  String get settings_languageSystem => 'Seguir sistema';

  @override
  String get settings_primaryCurrency => 'Moneda principal';

  @override
  String get settings_selectCurrency => 'Seleccionar moneda';

  @override
  String get settings_changeCurrencyWarning =>
      'Los cambios solo afectan a gastos futuros';

  @override
  String get settings_selectTheme => 'Seleccionar tema';

  @override
  String get settings_editName => 'Editar nombre';

  @override
  String get settings_nameLabel => 'Nombre';

  @override
  String get settings_nameHint => 'Usado para el título del informe de gastos';

  @override
  String get settings_saved => 'Guardado';

  @override
  String settings_cleanupFailed(String message) {
    return 'Error en la limpieza: $message';
  }

  @override
  String settings_cleanedFiles(int count) {
    return '$count archivos temporales limpiados';
  }

  @override
  String get settings_backupToCloud => 'Hacer copia en la nube';

  @override
  String get settings_backupConfirmMessage =>
      'Esto respaldará todos los gastos y recibos en Google Drive.\n\n¿Continuar?';

  @override
  String get settings_confirmRestoreTitle => 'Confirmar restauración';

  @override
  String settings_confirmRestoreDesc(String fileName) {
    return 'Esto reemplazará todos los datos actuales con \"$fileName\".\n\nEsta acción no se puede deshacer. ¿Continuar?';
  }

  @override
  String get settings_disconnectTitle => 'Desconectar cuenta de Google';

  @override
  String get settings_disconnectConfirm =>
      'La copia de seguridad en la nube no estará disponible después de desconectar.\n\n¿Desconectar?';

  @override
  String settings_connectFailed(String message) {
    return 'Error de conexión: $message';
  }

  @override
  String settings_disconnectFailed(String message) {
    return 'Error al desconectar: $message';
  }

  @override
  String get settings_googleConnected => 'Cuenta de Google conectada';

  @override
  String get settings_googleDisconnected => 'Cuenta de Google desconectada';

  @override
  String get category_label => 'Categoría (Opcional)';

  @override
  String get category_meals => 'Comidas';

  @override
  String get category_transport => 'Transporte';

  @override
  String get category_accommodation => 'Alojamiento';

  @override
  String get category_officeSupplies => 'Material de oficina';

  @override
  String get category_communication => 'Comunicación';

  @override
  String get category_entertainment => 'Entretenimiento';

  @override
  String get category_medical => 'Médico';

  @override
  String get category_other => 'Otro';

  @override
  String get category_statistics => 'Estadísticas por categoría';

  @override
  String get category_uncategorized => 'Sin categoría';

  @override
  String get excel_header_category => 'Categoría';

  @override
  String get semantic_category_prefix => 'Categoría';

  @override
  String semantic_expenseItem(String description) {
    return 'Elemento de gasto: $description';
  }

  @override
  String semantic_amount(String amount) {
    return 'Monto: $amount';
  }

  @override
  String semantic_originalAmount(String amount) {
    return 'Monto original: $amount';
  }

  @override
  String semantic_date(String date) {
    return 'Fecha: $date';
  }

  @override
  String semantic_rateSource(String source) {
    return 'Fuente de tasa: $source';
  }

  @override
  String get semantic_hasReceipt => 'Tiene imagen de recibo';

  @override
  String get semantic_tapForDetails => 'Toque para ver detalles';

  @override
  String get semantic_swipeToDelete => 'Deslice a la izquierda para eliminar';

  @override
  String get validation_amountRequired => 'Por favor ingrese un monto';

  @override
  String validation_amountTooSmall(num min) {
    return 'El monto no puede ser menor que $min';
  }

  @override
  String validation_amountTooLarge(num max) {
    return 'El monto no puede exceder $max';
  }

  @override
  String get validation_exchangeRateLabel => 'Tipo de cambio';

  @override
  String validation_exchangeRateHint(String currency) {
    return '1 $currency = ? HKD';
  }

  @override
  String get validation_exchangeRateRequired =>
      'Por favor ingrese el tipo de cambio';

  @override
  String get validation_exchangeRateInvalid =>
      'Por favor ingrese un tipo de cambio válido';

  @override
  String get rate_forceUpdated => 'Tipo de cambio actualizado forzosamente';

  @override
  String get rate_loading => 'Obteniendo tipo de cambio...';

  @override
  String get error_title => 'Error';

  @override
  String get error_invalidExpenseId => 'ID de gasto inválido';

  @override
  String get error_pageNotFound => 'Página no encontrada';
}
