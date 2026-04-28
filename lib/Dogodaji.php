if (!defined('ABSPATH')) exit;

/*
|--------------------------------------------------------------------------
| POMOĆNE FUNKCIJE
|--------------------------------------------------------------------------
*/
if (!function_exists('bkic_events_get_all')) {
    function bkic_events_get_all() {
        $events = get_option('bkic_events_data', []);
        return is_array($events) ? array_values($events) : [];
    }
}

if (!function_exists('bkic_events_save_all')) {
    function bkic_events_save_all($events) {
        update_option('bkic_events_data', array_values($events), false);
    }
}

if (!function_exists('bkic_events_generate_id')) {
    function bkic_events_generate_id() {
        return time() . wp_rand(100, 999);
    }
}

if (!function_exists('bkic_events_category_label')) {
    function bkic_events_category_label($category) {
        $map = [
            'predavanje' => 'Predavanje',
            'druzenje'   => 'Druženje',
            'radionica'  => 'Radionica',
            'omladina'   => 'Omladina',
            'porodica'   => 'Porodica',
        ];
        return $map[$category] ?? 'Predavanje';
    }
}

if (!function_exists('bkic_events_status_label')) {
    function bkic_events_status_label($status) {
        $map = [
            'open'   => 'Otvoreno',
            'soon'   => 'Uskoro',
            'closed' => 'Zatvoreno',
        ];
        return $map[$status] ?? 'Otvoreno';
    }
}

if (!function_exists('bkic_parse_event_datetime')) {
    function bkic_parse_event_datetime($date, $time = '00:00') {
        $date = trim((string)$date);
        $time = trim((string)$time);

        if ($date === '') return false;

        $formats = [
            'd.m.Y H:i',
            'd.m.Y H:i:s',
            'Y-m-d H:i',
            'Y-m-d H:i:s',
            'd-m-Y H:i',
        ];

        foreach ($formats as $format) {
            $dt = DateTime::createFromFormat($format, $date . ' ' . ($time ?: '00:00'));
            if ($dt instanceof DateTime) {
                return $dt->getTimestamp();
            }
        }

        $timestamp = strtotime(str_replace('.', '-', $date) . ' ' . ($time ?: '00:00'));
        return $timestamp ?: false;
    }
}

if (!function_exists('bkic_events_sort')) {
    function bkic_events_sort($events) {
        usort($events, function($a, $b) {
            $ad = bkic_parse_event_datetime($a['date'] ?? '', $a['time'] ?? '00:00');
            $bd = bkic_parse_event_datetime($b['date'] ?? '', $b['time'] ?? '00:00');
            return (int)$ad <=> (int)$bd;
        });
        return $events;
    }
}

if (!function_exists('bkic_find_event_by_id')) {
    function bkic_find_event_by_id($event_id) {
        $events = bkic_events_get_all();
        foreach ($events as $event) {
            if ((string)($event['id'] ?? '') === (string)$event_id) {
                return $event;
            }
        }
        return null;
    }
}

/*
|--------------------------------------------------------------------------
| PRIJAVE - POMOĆNE FUNKCIJE
|--------------------------------------------------------------------------
*/
if (!function_exists('bkic_event_registrations_option_key')) {
    function bkic_event_registrations_option_key($event_id) {
        return 'bkic_event_registrations_' . sanitize_key($event_id);
    }
}

if (!function_exists('bkic_get_event_registrations')) {
    function bkic_get_event_registrations($event_id) {
        $rows = get_option(bkic_event_registrations_option_key($event_id), []);
        return is_array($rows) ? array_values($rows) : [];
    }
}

if (!function_exists('bkic_save_event_registrations')) {
    function bkic_save_event_registrations($event_id, $rows) {
        update_option(bkic_event_registrations_option_key($event_id), array_values($rows), false);
    }
}

if (!function_exists('bkic_delete_event_registrations')) {
    function bkic_delete_event_registrations($event_id) {
        delete_option(bkic_event_registrations_option_key($event_id));
    }
}

if (!function_exists('bkic_is_user_registered_for_event')) {
    function bkic_is_user_registered_for_event($event_id, $user_id = 0) {
        $user_id = $user_id ?: get_current_user_id();
        if (!$user_id) return false;

        $rows = bkic_get_event_registrations($event_id);
        foreach ($rows as $row) {
            if ((int)($row['user_id'] ?? 0) === (int)$user_id) {
                return true;
            }
        }
        return false;
    }
}

if (!function_exists('bkic_get_event_registration_count')) {
    function bkic_get_event_registration_count($event_id) {
        return count(bkic_get_event_registrations($event_id));
    }
}

if (!function_exists('bkic_event_deadline_passed')) {
    function bkic_event_deadline_passed($event) {
        $deadline = trim((string)($event['deadline'] ?? ''));
        if ($deadline === '') return false;

        $ts = bkic_parse_event_datetime($deadline, '23:59');
        if (!$ts) return false;

        return current_time('timestamp') > $ts;
    }
}

if (!function_exists('bkic_event_is_full')) {
    function bkic_event_is_full($event) {
        $max = (int)($event['maxSeats'] ?? 0);
        if ($max <= 0) return false;

        $count = bkic_get_event_registration_count($event['id'] ?? '');
        return $count >= $max;
    }
}

if (!function_exists('bkic_event_can_register')) {
    function bkic_event_can_register($event) {
        if (!$event) return false;
        if (($event['status'] ?? '') === 'closed') return false;
        if (bkic_event_deadline_passed($event)) return false;
        if (bkic_event_is_full($event)) return false;
        return true;
    }
}

if (!function_exists('bkic_get_event_availability_label')) {
    function bkic_get_event_availability_label($event) {
        if (($event['status'] ?? '') === 'closed') return 'Zatvoreno';
        if (bkic_event_deadline_passed($event)) return 'Rok za prijavu je istekao';
        if (bkic_event_is_full($event)) return 'Popunjeno';
        return 'Otvoreno za prijavu';
    }
}

/*
|--------------------------------------------------------------------------
| AJAX: UPLOAD SLIKE
|--------------------------------------------------------------------------
*/
add_action('wp_ajax_bkic_upload_event_image', function() {
    if (!is_user_logged_in() || !current_user_can('manage_options')) {
        wp_send_json_error(['message' => 'Nema pristupa'], 403);
    }

    check_ajax_referer('bkic_events_frontend_nonce', 'nonce');

    if (empty($_FILES['image'])) {
        wp_send_json_error(['message' => 'Nijedna datoteka nije poslana.'], 400);
    }

    require_once ABSPATH . 'wp-admin/includes/file.php';
    require_once ABSPATH . 'wp-admin/includes/media.php';
    require_once ABSPATH . 'wp-admin/includes/image.php';

    $file = $_FILES['image'];
    $allowed_types = ['image/jpeg', 'image/png', 'image/webp', 'image/gif'];

    if (!in_array($file['type'], $allowed_types, true)) {
        wp_send_json_error(['message' => 'Dozvoljeni su samo JPG, PNG, WEBP i GIF.'], 400);
    }

    $attachment_id = media_handle_upload('image', 0);

    if (is_wp_error($attachment_id)) {
        wp_send_json_error(['message' => $attachment_id->get_error_message()], 400);
    }

    $url = wp_get_attachment_url($attachment_id);

    wp_send_json_success([
        'message' => 'Slika je uspješno uploadovana.',
        'url'     => $url,
        'id'      => $attachment_id,
    ]);
});

/*
|--------------------------------------------------------------------------
| AJAX: ADMIN LISTA DOGAĐAJA
|--------------------------------------------------------------------------
*/
add_action('wp_ajax_bkic_admin_list_events', function() {
    if (!is_user_logged_in() || !current_user_can('manage_options')) {
        wp_send_json_error(['message' => 'Nema pristupa'], 403);
    }

    $events = bkic_events_sort(bkic_events_get_all());

    foreach ($events as &$event) {
        $regs = bkic_get_event_registrations($event['id'] ?? '');
        $event['registrationsCount'] = count($regs);
        $event['registrations'] = $regs;
        $event['availabilityLabel'] = bkic_get_event_availability_label($event);
        $event['isFull'] = bkic_event_is_full($event);
        $event['deadlinePassed'] = bkic_event_deadline_passed($event);
    }
    unset($event);

    wp_send_json_success($events);
});

/*
|--------------------------------------------------------------------------
| AJAX: SAČUVAJ DOGAĐAJ
|--------------------------------------------------------------------------
*/
add_action('wp_ajax_bkic_save_event', function() {
    if (!is_user_logged_in() || !current_user_can('manage_options')) {
        wp_send_json_error(['message' => 'Nema pristupa'], 403);
    }

    check_ajax_referer('bkic_events_frontend_nonce', 'nonce');

    $id          = sanitize_text_field($_POST['id'] ?? '');
    $title       = sanitize_text_field($_POST['title'] ?? '');
    $description = sanitize_textarea_field($_POST['description'] ?? '');
    $date        = sanitize_text_field($_POST['date'] ?? '');
    $time        = sanitize_text_field($_POST['time'] ?? '');
    $location    = sanitize_text_field($_POST['location'] ?? '');
    $price       = sanitize_text_field($_POST['price'] ?? '');
    $category    = sanitize_text_field($_POST['category'] ?? 'predavanje');
    $status      = sanitize_text_field($_POST['status'] ?? 'open');
    $detailsUrl  = esc_url_raw($_POST['detailsUrl'] ?? '');
    $imageUrl    = esc_url_raw($_POST['imageUrl'] ?? '');
    $maxSeats    = max(0, intval($_POST['maxSeats'] ?? 0));
    $deadline    = sanitize_text_field($_POST['deadline'] ?? '');

    if ($title === '') {
        wp_send_json_error(['message' => 'Naslov nedostaje.'], 400);
    }

    if ($date === '') {
        wp_send_json_error(['message' => 'Datum nedostaje.'], 400);
    }

    $events = bkic_events_get_all();

    $item = [
        'id'            => $id ? $id : bkic_events_generate_id(),
        'title'         => $title,
        'description'   => $description,
        'date'          => $date,
        'time'          => $time,
        'location'      => $location,
        'price'         => $price,
        'category'      => $category,
        'categoryLabel' => bkic_events_category_label($category),
        'status'        => $status,
        'statusLabel'   => bkic_events_status_label($status),
        'detailsUrl'    => $detailsUrl,
        'imageUrl'      => $imageUrl,
        'maxSeats'      => $maxSeats,
        'deadline'      => $deadline,
    ];

    $updated = false;

    foreach ($events as $index => $event) {
        if ((string)($event['id'] ?? '') === (string)$item['id']) {
            $events[$index] = $item;
            $updated = true;
            break;
        }
    }

    if (!$updated) {
        $events[] = $item;
    }

    $events = bkic_events_sort($events);
    bkic_events_save_all($events);

    if (!$updated && function_exists('bkic_send_push_for_new_event_item')) {
        bkic_send_push_for_new_event_item($item);
    }

    wp_send_json_success([
        'message' => $updated ? 'Događaj je ažuriran.' : 'Događaj je kreiran.',
        'item'    => $item
    ]);
});

/*
|--------------------------------------------------------------------------
| AJAX: OBRIŠI DOGAĐAJ
|--------------------------------------------------------------------------
*/
add_action('wp_ajax_bkic_delete_event', function() {
    if (!is_user_logged_in() || !current_user_can('manage_options')) {
        wp_send_json_error(['message' => 'Nema pristupa'], 403);
    }

    check_ajax_referer('bkic_events_frontend_nonce', 'nonce');

    $id = sanitize_text_field($_POST['id'] ?? '');
    if ($id === '') {
        wp_send_json_error(['message' => 'ID nedostaje.'], 400);
    }

    $events = bkic_events_get_all();

    $events = array_values(array_filter($events, function($event) use ($id) {
        return (string)($event['id'] ?? '') !== (string)$id;
    }));

    bkic_events_save_all($events);
    bkic_delete_event_registrations($id);

    wp_send_json_success(['message' => 'Događaj je obrisan.']);
});

/*
|--------------------------------------------------------------------------
| AJAX: PRIJAVA
|--------------------------------------------------------------------------
*/
add_action('wp_ajax_bkic_register_event', function() {
    if (!is_user_logged_in()) {
        wp_send_json_error(['message' => 'Morate biti prijavljeni da biste se prijavili na događaj.'], 403);
    }

    check_ajax_referer('bkic_events_public_nonce', 'nonce');

    $event_id = sanitize_text_field($_POST['event_id'] ?? '');
    if ($event_id === '') {
        wp_send_json_error(['message' => 'ID događaja nedostaje.'], 400);
    }

    $event = bkic_find_event_by_id($event_id);
    if (!$event) {
        wp_send_json_error(['message' => 'Događaj nije pronađen.'], 404);
    }

    if (!bkic_event_can_register($event)) {
        wp_send_json_error(['message' => bkic_get_event_availability_label($event)], 400);
    }

    $user = wp_get_current_user();
    $user_id = get_current_user_id();
    $rows = bkic_get_event_registrations($event_id);

    foreach ($rows as $row) {
        if ((int)($row['user_id'] ?? 0) === (int)$user_id) {
            wp_send_json_success([
                'message'    => 'Već ste prijavljeni.',
                'count'      => count($rows),
                'registered' => true,
            ]);
        }
    }

    $rows[] = [
        'user_id'       => $user_id,
        'display_name'  => $user->display_name,
        'user_email'    => $user->user_email,
        'registered_at' => current_time('mysql'),
    ];

    bkic_save_event_registrations($event_id, $rows);

    wp_send_json_success([
        'message'    => 'Uspješno ste prijavljeni ✅',
        'count'      => count($rows),
        'registered' => true,
    ]);
});

/*
|--------------------------------------------------------------------------
| AJAX: ODJAVA
|--------------------------------------------------------------------------
*/
add_action('wp_ajax_bkic_unregister_event', function() {
    if (!is_user_logged_in()) {
        wp_send_json_error(['message' => 'Morate biti prijavljeni da biste se odjavili.'], 403);
    }

    check_ajax_referer('bkic_events_public_nonce', 'nonce');

    $event_id = sanitize_text_field($_POST['event_id'] ?? '');
    if ($event_id === '') {
        wp_send_json_error(['message' => 'ID događaja nedostaje.'], 400);
    }

    $user_id = get_current_user_id();
    $rows = bkic_get_event_registrations($event_id);

    $rows = array_values(array_filter($rows, function($row) use ($user_id) {
        return (int)($row['user_id'] ?? 0) !== (int)$user_id;
    }));

    bkic_save_event_registrations($event_id, $rows);

    wp_send_json_success([
        'message'    => 'Uspješno ste odjavljeni.',
        'count'      => count($rows),
        'registered' => false,
    ]);
});

/*
|--------------------------------------------------------------------------
| AJAX: EXPORT CSV
|--------------------------------------------------------------------------
*/
add_action('wp_ajax_bkic_export_event_csv', function() {
    if (!is_user_logged_in() || !current_user_can('manage_options')) {
        wp_die('Nema pristupa', 403);
    }

    $event_id = sanitize_text_field($_GET['event_id'] ?? '');
    $event = bkic_find_event_by_id($event_id);

    if (!$event) {
        wp_die('Događaj nije pronađen', 404);
    }

    $rows = bkic_get_event_registrations($event_id);
    $filename = 'dogadjaj-' . sanitize_file_name($event['title'] ?? 'prijave') . '-' . date('Y-m-d') . '.csv';

    nocache_headers();
    header('Content-Type: text/csv; charset=utf-8');
    header('Content-Disposition: attachment; filename=' . $filename);

    $out = fopen('php://output', 'w');
    fputcsv($out, ['Događaj', 'Ime', 'Email', 'Vrijeme prijave']);

    foreach ($rows as $row) {
        fputcsv($out, [
            $event['title'] ?? '',
            $row['display_name'] ?? '',
            $row['user_email'] ?? '',
            $row['registered_at'] ?? '',
        ]);
    }

    fclose($out);
    exit;
});

/*
|--------------------------------------------------------------------------
| SHORTCODE: ADMIN
|--------------------------------------------------------------------------
*/
add_shortcode('bkic_events_admin', function() {
    if (!is_user_logged_in() || !current_user_can('manage_options')) {
        return '<div style="padding:20px;border:1px solid #ddd;border-radius:12px;background:#fff;">Nema pristupa.</div>';
    }

    $nonce = wp_create_nonce('bkic_events_frontend_nonce');
    $ajax_url = admin_url('admin-ajax.php');

    ob_start();
    ?>
    <section class="bkic-admin-wrap">
      <header class="bkic-admin-header">
        <h2 class="bkic-admin-title">Događaji – Admin</h2>
        <p class="bkic-admin-sub">Kreiraj, uređuj, briši, uploaduj sliku i prati prijave</p>
      </header>

      <div class="bkic-admin-toolbar">
        <input id="bkicE_Search" class="bkicA-input" type="search" placeholder="Pretraga..." />
        <div class="bkicA-select-wrap">
          <select id="bkicE_Filter" class="bkicA-select">
            <option value="all" selected>Sve kategorije</option>
            <option value="predavanje">Predavanje</option>
            <option value="druzenje">Druženje</option>
            <option value="radionica">Radionica</option>
            <option value="omladina">Omladina</option>
            <option value="porodica">Porodica</option>
          </select>
        </div>
        <button id="bkicE_Reload" class="bkicA-btn" type="button">Osvježi</button>
      </div>

      <div id="bkicE_Status" class="bkicA-status" role="status" aria-live="polite"></div>

      <div class="bkicA-grid">
        <div class="bkicA-card">
          <h3 class="bkicA-h3" id="bkicE_FormTitle">Dodaj novi događaj</h3>

          <label class="bkicA-label" for="bkicE_Title">Naslov</label>
          <input id="bkicE_Title" class="bkicA-input" type="text" placeholder="Unesite naslov..." />

          <label class="bkicA-label" for="bkicE_Description">Opis</label>
          <textarea id="bkicE_Description" class="bkicA-textarea" rows="6" placeholder="Unesite opis događaja..."></textarea>

          <div class="bkicA-row">
            <div class="bkicA-field">
              <label class="bkicA-label" for="bkicE_Date">Datum</label>
              <input id="bkicE_Date" class="bkicA-input" type="date" />
            </div>
            <div class="bkicA-field">
              <label class="bkicA-label" for="bkicE_Time">Vrijeme</label>
              <input id="bkicE_Time" class="bkicA-input" type="time" />
            </div>
          </div>

          <div class="bkicA-row">
            <div class="bkicA-field">
              <label class="bkicA-label" for="bkicE_Location">Mjesto</label>
              <input id="bkicE_Location" class="bkicA-input" type="text" placeholder="BKIC SAFF, Odense" />
            </div>
            <div class="bkicA-field">
              <label class="bkicA-label" for="bkicE_Price">Cijena</label>
              <input id="bkicE_Price" class="bkicA-input" type="text" placeholder="Besplatno / 20 DKK" />
            </div>
          </div>

          <div class="bkicA-row">
            <div class="bkicA-field">
              <label class="bkicA-label" for="bkicE_Category">Kategorija</label>
              <div class="bkicA-select-wrap">
                <select id="bkicE_Category" class="bkicA-select">
                  <option value="predavanje">Predavanje</option>
                  <option value="druzenje">Druženje</option>
                  <option value="radionica">Radionica</option>
                  <option value="omladina">Omladina</option>
                  <option value="porodica">Porodica</option>
                </select>
              </div>
            </div>
            <div class="bkicA-field">
              <label class="bkicA-label" for="bkicE_StatusSel">Status</label>
              <div class="bkicA-select-wrap">
                <select id="bkicE_StatusSel" class="bkicA-select">
                  <option value="open">Otvoreno</option>
                  <option value="soon">Uskoro</option>
                  <option value="closed">Zatvoreno</option>
                </select>
              </div>
            </div>
          </div>

          <div class="bkicA-row">
            <div class="bkicA-field">
              <label class="bkicA-label" for="bkicE_MaxSeats">Maksimalan broj mjesta</label>
              <input id="bkicE_MaxSeats" class="bkicA-input" type="number" min="0" step="1" placeholder="0 = bez ograničenja" />
            </div>
            <div class="bkicA-field">
              <label class="bkicA-label" for="bkicE_Deadline">Rok prijave</label>
              <input id="bkicE_Deadline" class="bkicA-input" type="date" />
            </div>
          </div>

          <div class="bkicA-field">
            <label class="bkicA-label" for="bkicE_Details">Link za detalje</label>
            <input id="bkicE_Details" class="bkicA-input" type="text" placeholder="/dogadaj/ ili puni URL" />
          </div>

          <div class="bkicA-field">
            <label class="bkicA-label">Slika događaja</label>

            <div class="bkicA-upload">
              <input id="bkicE_ImageFile" class="bkicA-file-input" type="file" accept="image/*" />
              <input id="bkicE_ImageUrl" type="hidden" />
              <button id="bkicE_ChooseImage" class="bkicA-btn" type="button">Odaberi sliku</button>
              <span id="bkicE_FileName" class="bkicA-file-name">Nijedna datoteka nije odabrana</span>
            </div>

            <div id="bkicE_ImagePreviewWrap" class="bkicA-image-preview-wrap" style="display:none;">
              <img id="bkicE_ImagePreview" class="bkicA-image-preview" src="" alt="Pregled slike" />
              <button id="bkicE_RemoveImage" class="bkicA-btn" type="button">Ukloni sliku</button>
            </div>
          </div>

          <div class="bkicA-actions">
            <button id="bkicE_Save" class="bkicA-btn bkicA-btn-primary" type="button">Sačuvaj</button>
            <button id="bkicE_Cancel" class="bkicA-btn" type="button" style="display:none;">Otkaži</button>
          </div>
        </div>

        <div class="bkicA-card">
          <h3 class="bkicA-h3">Postojeći događaji</h3>
          <div id="bkicE_List" class="bkicA-list"></div>
        </div>
      </div>

      <template id="bkicE_ItemTpl">
        <article class="bkicA-item">
          <div class="bkicA-item-top">
            <div class="bkicA-item-main">
              <div class="bkicA-item-title"></div>
              <div class="bkicA-item-meta"></div>
              <div class="bkicA-item-count"></div>
              <div class="bkicA-item-availability"></div>
            </div>
            <div class="bkicA-item-buttons">
              <button class="bkicA-mini" data-act="edit" type="button">Uredi</button>
              <button class="bkicA-mini" data-act="csv" type="button">CSV</button>
              <button class="bkicA-mini bkicA-danger" data-act="delete" type="button">Obriši</button>
            </div>
          </div>
          <div class="bkicA-thumb-wrap" style="display:none;">
            <img class="bkicA-thumb" src="" alt="">
          </div>
          <div class="bkicA-item-excerpt"></div>
          <div class="bkicA-attendees"></div>
        </article>
      </template>
    </section>

    <style>
      .bkic-admin-wrap{max-width:1180px;margin:0 auto;padding:16px}
      .bkic-admin-header{margin-bottom:14px}
      .bkic-admin-title{margin:0 0 4px 0;font-size:30px;line-height:1.2}
      .bkic-admin-sub{margin:0;opacity:.8}

      .bkic-admin-toolbar{
        display:grid;
        grid-template-columns:minmax(0,1fr) 220px 130px;
        gap:12px;
        align-items:end;
        margin:16px 0 14px;
      }
      @media(max-width:900px){
        .bkic-admin-toolbar{grid-template-columns:1fr}
      }

      .bkicA-grid{
        display:grid;
        grid-template-columns:minmax(0,1fr) minmax(0,1fr);
        gap:16px;
        align-items:start;
      }
      @media(max-width:980px){
        .bkicA-grid{grid-template-columns:1fr}
      }

      .bkicA-card{
        border:1px solid rgba(0,0,0,.12);
        border-radius:18px;
        padding:18px;
        background:#fff;
        box-sizing:border-box;
      }

      .bkicA-h3{
        margin:0 0 12px 0;
        font-size:20px;
        line-height:1.3;
      }

      .bkicA-label{
        display:block;
        margin:12px 0 6px;
        font-size:14px;
        font-weight:700;
        opacity:.92;
      }

      .bkicA-field{min-width:0}

      .bkicA-input,
      .bkicA-select,
      .bkicA-textarea{
        width:100%;
        box-sizing:border-box;
        padding:14px 16px;
        border:1px solid rgba(0,0,0,.15);
        border-radius:12px;
        background:#fff;
        font-size:16px;
        line-height:1.45;
        min-height:56px;
        margin:0;
        color:#1f2937;
      }

      .bkicA-input::placeholder,
      .bkicA-textarea::placeholder{
        color:#9ca3af;
        opacity:1;
      }

      .bkicA-input[type="date"],
      .bkicA-input[type="time"]{
        -webkit-appearance:none;
        appearance:none;
      }

      .bkicA-select{
        -webkit-appearance:none;
        appearance:none;
        padding-right:44px;
        white-space:nowrap;
        overflow:hidden;
        text-overflow:ellipsis;
        cursor:pointer;
      }

      .bkicA-select-wrap{
        position:relative;
      }

      .bkicA-select-wrap::after{
        content:"";
        position:absolute;
        right:16px;
        top:50%;
        width:10px;
        height:10px;
        border-right:2px solid #4b5563;
        border-bottom:2px solid #4b5563;
        transform:translateY(-60%) rotate(45deg);
        pointer-events:none;
      }

      .bkicA-textarea{
        resize:vertical;
        min-height:140px;
      }

      .bkicA-row{
        display:grid;
        grid-template-columns:minmax(0,1fr) minmax(0,1fr);
        gap:12px;
        margin-top:2px;
      }
      @media(max-width:640px){
        .bkicA-row{grid-template-columns:1fr}
      }

      .bkicA-btn{
        padding:12px 16px;
        border:1px solid rgba(0,0,0,.14);
        border-radius:12px;
        background:#f4f4f4;
        cursor:pointer;
        font-size:15px;
        font-weight:700;
        line-height:1.2;
      }

      .bkicA-btn-primary{
        background:#0b63ce;
        color:#fff;
        border-color:#0b63ce;
      }

      .bkicA-actions{
        display:flex;
        gap:10px;
        justify-content:flex-end;
        align-items:center;
        margin-top:18px;
        flex-wrap:wrap;
      }
      @media(max-width:640px){
        .bkicA-actions{
          justify-content:stretch;
        }
        .bkicA-actions .bkicA-btn{
          flex:1 1 100%;
        }
      }

      .bkicA-status{
        margin:8px 0 14px;
        font-size:14px;
        opacity:.95;
      }
      .bkicA-status.is-error{color:#b32d2e;opacity:1}
      .bkicA-status.is-ok{color:#1d6f42;opacity:1}

      .bkicA-list{display:grid;gap:12px}

      .bkicA-item{
        border:1px solid rgba(0,0,0,.10);
        border-radius:14px;
        padding:14px;
        background:#fff;
      }

      .bkicA-item-top{
        display:flex;
        justify-content:space-between;
        gap:12px;
        align-items:flex-start;
      }
      @media(max-width:640px){
        .bkicA-item-top{
          flex-direction:column;
        }
      }

      .bkicA-item-main{min-width:0;flex:1}

      .bkicA-item-title{
        font-weight:800;
        font-size:17px;
        margin-bottom:4px;
        line-height:1.35;
        word-break:break-word;
      }

      .bkicA-item-meta{
        font-size:12px;
        opacity:.78;
        line-height:1.45;
      }

      .bkicA-item-count{
        margin-top:7px;
        font-size:13px;
        font-weight:800;
        color:#0b63ce;
      }

      .bkicA-item-availability{
        margin-top:6px;
        font-size:13px;
        font-weight:700;
        color:#725200;
      }

      .bkicA-item-excerpt{
        margin-top:10px;
        font-size:14px;
        opacity:.96;
        white-space:pre-wrap;
        line-height:1.55;
      }

      .bkicA-item-buttons{
        display:flex;
        gap:8px;
        flex-wrap:wrap;
        justify-content:flex-end;
      }
      @media(max-width:640px){
        .bkicA-item-buttons{
          justify-content:flex-start;
          width:100%;
        }
      }

      .bkicA-mini{
        padding:8px 11px;
        border-radius:10px;
        border:1px solid rgba(0,0,0,.15);
        background:#f6f6f6;
        cursor:pointer;
        font-size:13px;
        font-weight:700;
      }

      .bkicA-danger{
        background:rgba(179,45,46,.08);
        border-color:rgba(179,45,46,.25);
        color:#7a1f20;
      }

      .bkicA-attendees{
        margin-top:12px;
        padding-top:12px;
        border-top:1px dashed rgba(0,0,0,.12);
        font-size:13px;
      }

      .bkicA-attendees strong{
        display:block;
        margin-bottom:6px;
      }

      .bkicA-attendees ul{
        margin:0;
        padding-left:18px;
      }

      .bkicA-attendees li{
        margin:4px 0;
        line-height:1.45;
      }

      .bkicA-thumb-wrap{margin-top:10px}
      .bkicA-thumb{
        width:100%;
        max-width:280px;
        height:170px;
        object-fit:cover;
        border-radius:14px;
        display:block;
      }

      .bkicA-upload{
        display:flex;
        align-items:center;
        gap:12px;
        flex-wrap:wrap;
        padding:14px 16px;
        border:1px solid rgba(0,0,0,.15);
        border-radius:12px;
        background:#fff;
        min-height:56px;
        box-sizing:border-box;
      }

      .bkicA-file-input{
        position:absolute !important;
        left:-9999px !important;
        width:1px !important;
        height:1px !important;
        opacity:0 !important;
        pointer-events:none !important;
      }

      .bkicA-file-name{
        font-size:15px;
        color:#6b7280;
        line-height:1.4;
        word-break:break-word;
      }

      .bkicA-image-preview-wrap{
        margin-top:12px;
        display:flex;
        flex-direction:column;
        align-items:flex-start;
        gap:10px;
      }

      .bkicA-image-preview{
        width:100%;
        max-width:260px;
        height:auto;
        border-radius:14px;
        border:1px solid rgba(0,0,0,.12);
        display:block;
      }
    </style>

    <script>
    (async function(){
      const AJAX_URL = <?php echo wp_json_encode($ajax_url); ?>;
      const NONCE = <?php echo wp_json_encode($nonce); ?>;
      const $ = id => document.getElementById(id);

      const statusEl = $('bkicE_Status');
      const listEl = $('bkicE_List');
      const searchEl = $('bkicE_Search');
      const filterEl = $('bkicE_Filter');
      const reloadEl = $('bkicE_Reload');

      const formTitleEl = $('bkicE_FormTitle');
      const titleEl = $('bkicE_Title');
      const descriptionEl = $('bkicE_Description');
      const dateEl = $('bkicE_Date');
      const timeEl = $('bkicE_Time');
      const locationEl = $('bkicE_Location');
      const priceEl = $('bkicE_Price');
      const categoryEl = $('bkicE_Category');
      const statusSelectEl = $('bkicE_StatusSel');
      const detailsEl = $('bkicE_Details');
      const maxSeatsEl = $('bkicE_MaxSeats');
      const deadlineEl = $('bkicE_Deadline');
      const imageFileEl = $('bkicE_ImageFile');
      const imageUrlEl = $('bkicE_ImageUrl');
      const imagePreviewWrapEl = $('bkicE_ImagePreviewWrap');
      const imagePreviewEl = $('bkicE_ImagePreview');
      const chooseImageEl = $('bkicE_ChooseImage');
      const fileNameEl = $('bkicE_FileName');
      const removeImageEl = $('bkicE_RemoveImage');
      const saveEl = $('bkicE_Save');
      const cancelEl = $('bkicE_Cancel');
      const tpl = $('bkicE_ItemTpl');

      let items = [];
      let editingId = '';

      function setStatus(msg, type){
        statusEl.textContent = msg || '';
        statusEl.classList.remove('is-error','is-ok');
        if (type === 'error') statusEl.classList.add('is-error');
        if (type === 'ok') statusEl.classList.add('is-ok');
      }

      function excerpt(s, n=180){
        s = String(s||'').trim();
        if (s.length <= n) return s;
        return s.slice(0,n-1) + '…';
      }

      function ajaxUrl(action, params = {}){
        const u = new URL(AJAX_URL);
        u.searchParams.set('action', action);
        u.searchParams.set('_', String(Date.now()));
        Object.keys(params).forEach(k => u.searchParams.set(k, params[k]));
        return u.toString();
      }

      function formatDateForInput(dateStr){
        const s = String(dateStr || '').trim();
        if (!s) return '';
        const m = s.match(/^(\d{2})\.(\d{2})\.(\d{4})$/);
        if (m) return ${m[3]}-${m[2]}-${m[1]};
        return s;
      }

      function formatDateForStorage(dateStr){
        const s = String(dateStr || '').trim();
        if (!s) return '';
        const m = s.match(/^(\d{4})-(\d{2})-(\d{2})$/);
        if (m) return ${m[3]}.${m[2]}.${m[1]};
        return s;
      }

      function setImagePreview(url){
        if (url) {
          imagePreviewEl.src = url;
          imagePreviewWrapEl.style.display = 'flex';
        } else {
          imagePreviewEl.src = '';
          imagePreviewWrapEl.style.display = 'none';
        }
      }

      function setFileName(name){
        fileNameEl.textContent = name || 'Nijedna datoteka nije odabrana';
      }

      function resetForm(){
        editingId = '';
        formTitleEl.textContent = 'Dodaj novi događaj';
        titleEl.value = '';
        descriptionEl.value = '';
        dateEl.value = '';
        timeEl.value = '';
        locationEl.value = '';
        priceEl.value = '';
        categoryEl.value = 'predavanje';
        statusSelectEl.value = 'open';
        detailsEl.value = '';
        maxSeatsEl.value = '';
        deadlineEl.value = '';
        imageFileEl.value = '';
        imageUrlEl.value = '';
        setFileName('');
        setImagePreview('');
        cancelEl.style.display = 'none';
        saveEl.textContent = 'Sačuvaj';
      }

      function startEdit(item){
        editingId = String(item.id || '');
        formTitleEl.textContent = Uredi događaj #${editingId};
        titleEl.value = item.title || '';
        descriptionEl.value = item.description || '';
        dateEl.value = formatDateForInput(item.date || '');
        timeEl.value = item.time || '';
        locationEl.value = item.location || '';
        priceEl.value = item.price || '';
        categoryEl.value = item.category || 'predavanje';
        statusSelectEl.value = item.status || 'open';
        detailsEl.value = item.detailsUrl || '';
        maxSeatsEl.value = item.maxSeats || '';
        deadlineEl.value = formatDateForInput(item.deadline || '');
        imageFileEl.value = '';
        imageUrlEl.value = item.imageUrl || '';
        setFileName('');
        setImagePreview(item.imageUrl || '');
        cancelEl.style.display = 'inline-block';
        saveEl.textContent = 'Ažuriraj';
        window.scrollTo({top: 0, behavior: 'smooth'});
      }

      async function uploadImageIfNeeded(){
        const file = imageFileEl.files && imageFileEl.files[0] ? imageFileEl.files[0] : null;
        if (!file) return imageUrlEl.value.trim();

        const form = new FormData();
        form.append('nonce', NONCE);
        form.append('image', file);

        const res = await fetch(ajaxUrl('bkic_upload_event_image'), {
          method: 'POST',
          credentials: 'include',
          body: form
        });

        const json = await res.json().catch(()=>null);

        if (!res.ok || !json || json.success === false) {
          const msg = (json && json.data && (json.data.message || json.data)) ? (json.data.message || json.data) : HTTP ${res.status};
          throw new Error(msg);
        }

        const url = (json.data && json.data.url) ? json.data.url : '';
        imageUrlEl.value = url;
        setImagePreview(url);
        return url;
      }

      function applyFilters(){
        const q = (searchEl.value || '').toLowerCase().trim();
        const f = filterEl.value;

        let out = [...items];

        if (f !== 'all') {
          out = out.filter(item => (item.category || '') === f);
        }

        if (q) {
          out = out.filter(item => {
            const hay = ${item.title || ''} ${item.description || ''} ${item.date || ''} ${item.location || ''}.toLowerCase();
            return hay.includes(q);
          });
        }

        return out;
      }

      function render(){
        listEl.innerHTML = '';
        const out = applyFilters();

        if (!out.length){
          listEl.innerHTML = '<p>Nema događaja.</p>';
          return;
        }

        const frag = document.createDocumentFragment();

        out.forEach(item => {
          const node = tpl.content.cloneNode(true);

          node.querySelector('.bkicA-item-title').textContent = item.title || '(bez naslova)';
          node.querySelector('.bkicA-item-meta').textContent =
            #${item.id} • ${item.categoryLabel || item.category || ''} • ${item.statusLabel || item.status || ''} • ${item.date || ''} ${item.time || ''};
          node.querySelector('.bkicA-item-count').textContent =
            Broj prijavljenih: ${item.registrationsCount || 0}${item.maxSeats ? ' / ' + item.maxSeats : ''};
          node.querySelector('.bkicA-item-availability').textContent =
            Status prijave: ${item.availabilityLabel || ''};
          node.querySelector('.bkicA-item-excerpt').textContent = excerpt(item.description || '');

          const thumbWrap = node.querySelector('.bkicA-thumb-wrap');
          const thumb = node.querySelector('.bkicA-thumb');
          if (item.imageUrl) {
            thumb.src = item.imageUrl;
            thumbWrap.style.display = 'block';
          }

          const attWrap = node.querySelector('.bkicA-attendees');
          const regs = Array.isArray(item.registrations) ? item.registrations : [];

          if (regs.length) {
            const strong = document.createElement('strong');
            strong.textContent = 'Lista prijavljenih';
            const ul = document.createElement('ul');

            regs.forEach(r => {
              const li = document.createElement('li');
              li.textContent = ${r.display_name || 'Korisnik'} (${r.user_email || '-'}) – ${r.registered_at || ''};
              ul.appendChild(li);
            });

            attWrap.appendChild(strong);
            attWrap.appendChild(ul);
          } else {
            attWrap.innerHTML = '<strong>Lista prijavljenih</strong><div>Niko se još nije prijavio.</div>';
          }

          node.querySelector('[data-act="edit"]').addEventListener('click', ()=> startEdit(item));
          node.querySelector('[data-act="delete"]').addEventListener('click', ()=> deleteItem(item.id));
          node.querySelector('[data-act="csv"]').addEventListener('click', ()=> {
            window.location.href = ajaxUrl('bkic_export_event_csv', {event_id: item.id});
          });

          frag.appendChild(node);
        });

        listEl.appendChild(frag);
        setStatus(${out.length} događaja prikazano., 'ok');
      }

      async function load(){
        setStatus('Učitavanje događaja...', null);

        try {
          const res = await fetch(ajaxUrl('bkic_admin_list_events'), {
            method: 'GET',
            credentials: 'include',
            cache: 'no-store',
            headers: { 'Accept': 'application/json' }
          });

          const json = await res.json().catch(()=>null);

          if (!res.ok || !json || json.success === false){
            const msg = (json && json.data && (json.data.message || json.data)) ? (json.data.message || json.data) : HTTP ${res.status};
            setStatus(Greška pri učitavanju: ${msg}, 'error');
            return;
          }

          items = Array.isArray(json.data) ? json.data : [];
          render();
        } catch(e){
          console.error(e);
          setStatus('Došlo je do greške pri učitavanju.', 'error');
        }
      }

      async function save(){
        const title = titleEl.value.trim();
        const description = descriptionEl.value.trim();
        const date = formatDateForStorage(dateEl.value.trim());
        const time = timeEl.value.trim();
        const location = locationEl.value.trim();
        const price = priceEl.value.trim();
        const category = categoryEl.value;
        const status = statusSelectEl.value;
        const detailsUrl = detailsEl.value.trim();
        const maxSeats = maxSeatsEl.value.trim();
        const deadline = formatDateForStorage(deadlineEl.value.trim());

        if (!title){
          setStatus('Naslov nedostaje.', 'error');
          return;
        }

        if (!date){
          setStatus('Datum nedostaje.', 'error');
          return;
        }

        let imageUrl = imageUrlEl.value.trim();

        try {
          if (imageFileEl.files && imageFileEl.files[0]) {
            setStatus('Uploadovanje slike...', null);
            imageUrl = await uploadImageIfNeeded();
          }

          setStatus(editingId ? 'Ažuriranje događaja...' : 'Kreiranje događaja...', null);

          const form = new FormData();
          form.append('nonce', NONCE);
          form.append('id', editingId);
          form.append('title', title);
          form.append('description', description);
          form.append('date', date);
          form.append('time', time);
          form.append('location', location);
          form.append('price', price);
          form.append('category', category);
          form.append('status', status);
          form.append('detailsUrl', detailsUrl);
          form.append('imageUrl', imageUrl);
          form.append('maxSeats', maxSeats);
          form.append('deadline', deadline);

          const res = await fetch(ajaxUrl('bkic_save_event'), {
            method: 'POST',
            credentials: 'include',
            body: form
          });

          const json = await res.json().catch(()=>null);

          if (!res.ok || !json || json.success === false){
            const msg = (json && json.data && (json.data.message || json.data)) ? (json.data.message || json.data) : HTTP ${res.status};
            setStatus(Sačuvavanje nije uspjelo: ${msg}, 'error');
            return;
          }

          setStatus('Događaj je uspješno sačuvan ✅', 'ok');
          resetForm();
          await load();

        } catch(e){
          console.error(e);
          setStatus(Greška: ${e.message || 'Nepoznata greška'}, 'error');
        }
      }

      async function deleteItem(id){
        if (!confirm(Da li ste sigurni da želite obrisati događaj #${id}?)) return;

        try {
          setStatus('Brisanje događaja...', null);

          const form = new FormData();
          form.append('nonce', NONCE);
          form.append('id', String(id));

          const res = await fetch(ajaxUrl('bkic_delete_event'), {
            method: 'POST',
            credentials: 'include',
            body: form
          });

          const json = await res.json().catch(()=>null);

          if (!res.ok || !json || json.success === false){
            const msg = (json && json.data && (json.data.message || json.data)) ? (json.data.message || json.data) : HTTP ${res.status};
            setStatus(Brisanje nije uspjelo: ${msg}, 'error');
            return;
          }

          setStatus('Događaj je obrisan ✅', 'ok');
          await load();
        } catch(e){
          console.error(e);
          setStatus('Došlo je do greške pri brisanju.', 'error');
        }
      }

      chooseImageEl.addEventListener('click', function(){
        imageFileEl.click();
      });

      imageFileEl.addEventListener('change', function(){
        const file = imageFileEl.files && imageFileEl.files[0] ? imageFileEl.files[0] : null;
        if (!file) {
          setFileName('');
          return;
        }

        setFileName(file.name);

        const reader = new FileReader();
        reader.onload = function(e){
          setImagePreview(e.target.result || '');
        };
        reader.readAsDataURL(file);
      });

      removeImageEl.addEventListener('click', function(){
        imageFileEl.value = '';
        imageUrlEl.value = '';
        setFileName('');
        setImagePreview('');
      });

      searchEl.addEventListener('input', render);
      filterEl.addEventListener('change', render);
      reloadEl.addEventListener('click', load);
      saveEl.addEventListener('click', save);
      cancelEl.addEventListener('click', resetForm);

      resetForm();
      await load();
    })();
    </script>
    <?php
    return ob_get_clean();
});

/*
|--------------------------------------------------------------------------
| SHORTCODE: FRONTEND DOGAĐAJI
|--------------------------------------------------------------------------
*/
add_shortcode('bkic_events', function() {
    $events = bkic_events_sort(bkic_events_get_all());
    $is_logged_in = is_user_logged_in();
    $ajax_url = admin_url('admin-ajax.php');
    $nonce = wp_create_nonce('bkic_events_public_nonce');
    $login_url = wp_login_url(get_permalink());

    if (empty($events)) {
        return '<div class="bkic-empty">Trenutno nema dostupnih događaja.</div>';
    }

    ob_start();
    ?>
    <div class="bkic-events-wrap">
      <div class="bkic-events-grid">
        <?php foreach ($events as $event):
            $event_id = $event['id'] ?? '';
            $count = bkic_get_event_registration_count($event_id);
            $registered = $is_logged_in ? bkic_is_user_registered_for_event($event_id) : false;
            $can_register = bkic_event_can_register($event);
            $availability = bkic_get_event_availability_label($event);
            $max_seats = (int)($event['maxSeats'] ?? 0);
        ?>
          <article class="bkic-event-card" data-event-id="<?php echo esc_attr($event_id); ?>">
            <?php if (!empty($event['imageUrl'])): ?>
              <div class="bkic-event-image-wrap">
                <img class="bkic-event-image" src="<?php echo esc_url($event['imageUrl']); ?>" alt="<?php echo esc_attr($event['title'] ?? ''); ?>">
              </div>
            <?php endif; ?>

            <div class="bkic-event-top">
              <span class="bkic-event-category"><?php echo esc_html($event['categoryLabel'] ?? ''); ?></span>
              <span class="bkic-event-status <?php echo esc_attr($event['status'] ?? ''); ?>"><?php echo esc_html($event['statusLabel'] ?? ''); ?></span>
            </div>

            <h3 class="bkic-event-title"><?php echo esc_html($event['title'] ?? ''); ?></h3>
            <p class="bkic-event-desc"><?php echo esc_html($event['description'] ?? ''); ?></p>

            <div class="bkic-event-info">
              <div><strong>Datum:</strong> <?php echo esc_html($event['date'] ?? ''); ?></div>
              <div><strong>Vrijeme:</strong> <?php echo esc_html($event['time'] ?? ''); ?></div>
              <div><strong>Mjesto:</strong> <?php echo esc_html($event['location'] ?? ''); ?></div>
              <div><strong>Cijena:</strong> <?php echo esc_html($event['price'] ?? ''); ?></div>
              <?php if (!empty($event['deadline'])): ?>
                <div><strong>Rok prijave:</strong> <?php echo esc_html($event['deadline']); ?></div>
              <?php endif; ?>
            </div>

            <div class="bkic-event-meta-line">
              <span class="bkic-count-badge">
                Prijavljeni:
                <strong class="bkic-reg-count"><?php echo (int)$count; ?></strong>
                <?php if ($max_seats > 0): ?>
                  / <?php echo (int)$max_seats; ?>
                <?php endif; ?>
              </span>

              <?php if ($registered): ?>
                <span class="bkic-user-state is-registered">Već ste prijavljeni</span>
              <?php elseif (!$is_logged_in): ?>
                <span class="bkic-user-state">Potrebna prijava</span>
              <?php else: ?>
                <span class="bkic-user-state"><?php echo esc_html($availability); ?></span>
              <?php endif; ?>
            </div>

            <div class="bkic-event-actions">
              <?php if (!$is_logged_in): ?>
                <a class="bkic-btn bkic-btn-primary" href="<?php echo esc_url($login_url); ?>">Prijavite se</a>
              <?php else: ?>
                <?php if ($registered): ?>
                  <button
                    class="bkic-btn bkic-btn-danger bkic-reg-toggle"
                    type="button"
                    data-event-id="<?php echo esc_attr($event_id); ?>"
                    data-registered="1">
                    Odjavi se
                  </button>
                <?php elseif ($can_register): ?>
                  <button
                    class="bkic-btn bkic-btn-primary bkic-reg-toggle"
                    type="button"
                    data-event-id="<?php echo esc_attr($event_id); ?>"
                    data-registered="0">
                    Prijavi se
                  </button>
                <?php else: ?>
                  <button class="bkic-btn bkic-btn-disabled" type="button" disabled><?php echo esc_html($availability); ?></button>
                <?php endif; ?>
              <?php endif; ?>

              <?php if (!empty($event['detailsUrl'])): ?>
                <a class="bkic-btn bkic-btn-secondary" href="<?php echo esc_url($event['detailsUrl']); ?>">Detalji</a>
              <?php endif; ?>
            </div>

            <div class="bkic-event-note" aria-live="polite"></div>
          </article>
        <?php endforeach; ?>
      </div>
    </div>

    <style>
      .bkic-events-wrap{max-width:1240px;margin:0 auto;padding:10px 0}
      .bkic-events-grid{display:grid;grid-template-columns:repeat(3,minmax(0,1fr));gap:20px}

      .bkic-event-card{
        background:linear-gradient(180deg,#0f1830 0%,#111827 100%);
        color:#fff;
        border:1px solid rgba(255,255,255,.08);
        border-radius:24px;
        padding:20px;
        display:flex;
        flex-direction:column;
        gap:14px;
        box-shadow:0 10px 25px rgba(0,0,0,.20);
        overflow:hidden;
      }

      .bkic-event-image-wrap{margin:-20px -20px 6px -20px}
      .bkic-event-image{
        width:100%;
        height:240px;
        object-fit:cover;
        display:block;
      }

      .bkic-event-top{
        display:flex;
        justify-content:space-between;
        gap:10px;
        align-items:center;
      }

      .bkic-event-category,.bkic-event-status{
        padding:8px 14px;
        border-radius:999px;
        font-size:13px;
        font-weight:800;
      }

      .bkic-event-category{background:#3b2d10;color:#ffe1a1}
      .bkic-event-status.open{background:#183320;color:#d9f6dd}
      .bkic-event-status.soon{background:#4c3914;color:#ffe4aa}
      .bkic-event-status.closed{background:#442020;color:#ffd3d1}

      .bkic-event-title{
        margin:0;
        font-size:34px;
        line-height:1.08;
        color:#f3d37d;
      }

      .bkic-event-desc{
        margin:0;
        color:rgba(255,255,255,.9);
        font-size:19px;
        line-height:1.55;
      }

      .bkic-event-info{
        display:grid;
        gap:10px;
        font-size:16px;
        background:rgba(255,255,255,.05);
        padding:14px;
        border-radius:16px;
      }

      .bkic-event-meta-line{
        display:flex;
        justify-content:space-between;
        gap:10px;
        flex-wrap:wrap;
        align-items:center;
      }

      .bkic-count-badge{
        background:#d7b15d;
        color:#111;
        padding:8px 12px;
        border-radius:999px;
        font-weight:800;
      }

      .bkic-user-state{
        background:rgba(255,255,255,.08);
        padding:8px 12px;
        border-radius:999px;
        font-size:14px;
      }

      .bkic-user-state.is-registered{
        background:#183320;
        color:#d9f6dd;
        font-weight:800;
      }

      .bkic-event-actions{
        display:flex;
        gap:12px;
        flex-wrap:wrap;
        margin-top:auto;
      }

      .bkic-btn{
        padding:14px 18px;
        border-radius:14px;
        text-decoration:none;
        font-weight:800;
        border:none;
        cursor:pointer;
        font-size:18px;
        line-height:1.2;
      }

      .bkic-btn-primary{background:#d7b15d;color:#111}
      .bkic-btn-secondary{background:rgba(255,255,255,.08);color:#fff}
      .bkic-btn-danger{background:#7a1f20;color:#fff}
      .bkic-btn-disabled{background:#4b5563;color:#fff;cursor:not-allowed}

      .bkic-event-note{
        min-height:22px;
        font-size:14px;
        color:#cde7d1;
      }

      .bkic-event-note.is-error{color:#ffd3d1}

      .bkic-empty{
        padding:18px;
        border:1px solid #ddd;
        border-radius:12px;
        background:#fff;
      }

      @media(max-width:1024px){
        .bkic-events-grid{grid-template-columns:1fr 1fr}
        .bkic-event-title{font-size:28px}
        .bkic-event-desc{font-size:18px}
      }

      @media(max-width:640px){
        .bkic-events-grid{grid-template-columns:1fr}
        .bkic-event-title{font-size:24px}
        .bkic-event-desc{font-size:16px}
        .bkic-event-image{height:200px}
        .bkic-btn{width:100%;text-align:center}
      }
    </style>

    <script>
    (function(){
      const AJAX_URL = <?php echo wp_json_encode($ajax_url); ?>;
      const NONCE = <?php echo wp_json_encode($nonce); ?>;

      function ajaxUrl(action){
        const u = new URL(AJAX_URL);
        u.searchParams.set('action', action);
        u.searchParams.set('_', String(Date.now()));
        return u.toString();
      }

      async function toggleRegistration(btn){
        const card = btn.closest('.bkic-event-card');
        if (!card) return;

        const eventId = btn.getAttribute('data-event-id') || '';
        const registered = btn.getAttribute('data-registered') === '1';
        const note = card.querySelector('.bkic-event-note');
        const countEl = card.querySelector('.bkic-reg-count');
        const stateEl = card.querySelector('.bkic-user-state');

        btn.disabled = true;
        note.textContent = registered ? 'Odjava u toku...' : 'Prijava u toku...';
        note.classList.remove('is-error');

        try {
          const form = new FormData();
          form.append('nonce', NONCE);
          form.append('event_id', eventId);

          const res = await fetch(ajaxUrl(registered ? 'bkic_unregister_event' : 'bkic_register_event'), {
            method: 'POST',
            credentials: 'include',
            body: form
          });

          const json = await res.json().catch(()=>null);

          if (!res.ok || !json || json.success === false){
            const msg = (json && json.data && (json.data.message || json.data)) ? (json.data.message || json.data) : HTTP ${res.status};
            note.textContent = msg;
            note.classList.add('is-error');
            btn.disabled = false;
            return;
          }

          const data = json.data || {};
          const isNowRegistered = !!data.registered;
          const count = Number(data.count || 0);

          if (countEl) countEl.textContent = String(count);

          if (isNowRegistered){
            btn.textContent = 'Odjavi se';
            btn.setAttribute('data-registered', '1');
            btn.classList.remove('bkic-btn-primary');
            btn.classList.add('bkic-btn-danger');
            if (stateEl){
              stateEl.textContent = 'Već ste prijavljeni';
              stateEl.classList.add('is-registered');
            }
          } else {
            btn.textContent = 'Prijavi se';
            btn.setAttribute('data-registered', '0');
            btn.classList.remove('bkic-btn-danger');
            btn.classList.add('bkic-btn-primary');
            if (stateEl){
              stateEl.textContent = 'Niste prijavljeni';
              stateEl.classList.remove('is-registered');
            }
          }

          note.textContent = data.message || 'Status je ažuriran.';
          btn.disabled = false;

        } catch(e){
          console.error(e);
          note.textContent = 'Došlo je do greške.';
          note.classList.add('is-error');
          btn.disabled = false;
        }
      }

      document.querySelectorAll('.bkic-reg-toggle').forEach(btn => {
        btn.addEventListener('click', function(){
          toggleRegistration(btn);
        });
      });
    })();
    </script>
    <?php
    return ob_get_clean();
});
add_action('rest_api_init', function () {

    register_rest_route('bkicsaff/v1', '/admin/events', [
        'methods'             => 'GET',
        'callback'            => 'bkic_mobile_admin_events_list',
        'permission_callback' => 'bkic_mobile_admin_permission',
    ]);

    register_rest_route('bkicsaff/v1', '/admin/events/save', [
        'methods'             => 'POST',
        'callback'            => 'bkic_mobile_admin_events_save',
        'permission_callback' => 'bkic_mobile_admin_permission',
    ]);

    register_rest_route('bkicsaff/v1', '/admin/events/delete', [
        'methods'             => 'POST',
        'callback'            => 'bkic_mobile_admin_events_delete',
        'permission_callback' => 'bkic_mobile_admin_permission',
    ]);

    register_rest_route('bkicsaff/v1', '/admin/events/upload-image', [
        'methods'             => 'POST',
        'callback'            => 'bkic_mobile_admin_events_upload_image',
        'permission_callback' => 'bkic_mobile_admin_permission',
    ]);
});
/* ======================================================
 * BKIC SAFF – MOBILE API: ADMIN EVENTS
 * ====================================================== */

add_action('rest_api_init', function () {

    register_rest_route('bkicsaff/v1', '/admin/events', [
        'methods'             => 'GET',
        'callback'            => 'bkic_mobile_admin_events_list',
        'permission_callback' => 'bkic_mobile_admin_permission',
    ]);

    register_rest_route('bkicsaff/v1', '/admin/events/save', [
        'methods'             => 'POST',
        'callback'            => 'bkic_mobile_admin_events_save',
        'permission_callback' => 'bkic_mobile_admin_permission',
    ]);

    register_rest_route('bkicsaff/v1', '/admin/events/delete', [
        'methods'             => 'POST',
        'callback'            => 'bkic_mobile_admin_events_delete',
        'permission_callback' => 'bkic_mobile_admin_permission',
    ]);

    register_rest_route('bkicsaff/v1', '/admin/events/upload-image', [
        'methods'             => 'POST',
        'callback'            => 'bkic_mobile_admin_events_upload_image',
        'permission_callback' => 'bkic_mobile_admin_permission',
    ]);
});

if (!function_exists('bkic_mobile_admin_permission')) {
    function bkic_mobile_admin_permission(WP_REST_Request $request) {
        if (!function_exists('bkic_get_authenticated_user')) {
            return false;
        }

        $user = bkic_get_authenticated_user($request);

        if (!$user || !($user instanceof WP_User)) {
            return false;
        }

        return user_can($user, 'manage_options');
    }
}

if (!function_exists('bkic_mobile_admin_events_list')) {
    function bkic_mobile_admin_events_list(WP_REST_Request $request) {
        $events = bkic_events_sort(bkic_events_get_all());

        foreach ($events as &$event) {
            $regs = bkic_get_event_registrations($event['id'] ?? '');

            $event['registrationsCount'] = count($regs);
            $event['registrations'] = array_values($regs);
            $event['availabilityLabel'] = bkic_get_event_availability_label($event);
            $event['isFull'] = bkic_event_is_full($event);
            $event['deadlinePassed'] = bkic_event_deadline_passed($event);
        }
        unset($event);

        return rest_ensure_response([
            'success' => true,
            'data'    => array_values($events),
        ]);
    }
}

if (!function_exists('bkic_mobile_admin_events_save')) {
    function bkic_mobile_admin_events_save(WP_REST_Request $request) {
        $id          = sanitize_text_field((string) $request->get_param('id'));
        $title       = sanitize_text_field((string) $request->get_param('title'));
        $description = sanitize_textarea_field((string) $request->get_param('description'));
        $date        = sanitize_text_field((string) $request->get_param('date'));
        $time        = sanitize_text_field((string) $request->get_param('time'));
        $location    = sanitize_text_field((string) $request->get_param('location'));
        $price       = sanitize_text_field((string) $request->get_param('price'));
        $category    = sanitize_text_field((string) ($request->get_param('category') ?: 'predavanje'));
        $status      = sanitize_text_field((string) ($request->get_param('status') ?: 'open'));
        $detailsUrl  = esc_url_raw((string) $request->get_param('detailsUrl'));
        $imageUrl    = esc_url_raw((string) $request->get_param('imageUrl'));
        $maxSeats    = max(0, intval($request->get_param('maxSeats')));
        $deadline    = sanitize_text_field((string) $request->get_param('deadline'));

        if ($title === '') {
            return new WP_Error('bkic_missing_title', 'Naslov nedostaje.', ['status' => 400]);
        }

        if ($date === '') {
            return new WP_Error('bkic_missing_date', 'Datum nedostaje.', ['status' => 400]);
        }

        $events = bkic_events_get_all();

        $item = [
            'id'            => $id !== '' ? $id : bkic_events_generate_id(),
            'title'         => $title,
            'description'   => $description,
            'date'          => $date,
            'time'          => $time,
            'location'      => $location,
            'price'         => $price,
            'category'      => $category,
            'categoryLabel' => bkic_events_category_label($category),
            'status'        => $status,
            'statusLabel'   => bkic_events_status_label($status),
            'detailsUrl'    => $detailsUrl,
            'imageUrl'      => $imageUrl,
            'maxSeats'      => $maxSeats,
            'deadline'      => $deadline,
        ];

        $updated = false;

        foreach ($events as $index => $event) {
            if ((string) ($event['id'] ?? '') === (string) $item['id']) {
                $events[$index] = $item;
                $updated = true;
                break;
            }
        }

        if (!$updated) {
            $events[] = $item;
        }

        $events = bkic_events_sort($events);
        bkic_events_save_all($events);

        return rest_ensure_response([
            'success' => true,
            'message' => $updated ? 'Događaj je ažuriran.' : 'Događaj je kreiran.',
            'data'    => ['item' => $item],
        ]);
    }
}

if (!function_exists('bkic_mobile_admin_events_delete')) {
    function bkic_mobile_admin_events_delete(WP_REST_Request $request) {
        $id = sanitize_text_field((string) $request->get_param('id'));

        if ($id === '') {
            return new WP_Error('bkic_missing_id', 'ID nedostaje.', ['status' => 400]);
        }

        $events = bkic_events_get_all();

        $events = array_values(array_filter($events, function ($event) use ($id) {
            return (string) ($event['id'] ?? '') !== (string) $id;
        }));

        bkic_events_save_all($events);
        bkic_delete_event_registrations($id);

        return rest_ensure_response([
            'success' => true,
            'message' => 'Događaj je obrisan.',
        ]);
    }
}

if (!function_exists('bkic_mobile_admin_events_upload_image')) {
    function bkic_mobile_admin_events_upload_image(WP_REST_Request $request) {

        if (empty($_FILES['image'])) {
            return new WP_Error(
                'bkic_no_image',
                'Nijedna slika nije poslana.',
                ['status' => 400]
            );
        }

        require_once ABSPATH . 'wp-admin/includes/file.php';
        require_once ABSPATH . 'wp-admin/includes/media.php';
        require_once ABSPATH . 'wp-admin/includes/image.php';

        $file = $_FILES['image'];

        // 🔥 FIX: Brug filendelse i stedet for MIME-type
        $filename = strtolower($file['name'] ?? '');
        $ext = pathinfo($filename, PATHINFO_EXTENSION);

        $allowed_extensions = ['jpg', 'jpeg', 'png', 'webp', 'gif'];

        if (!in_array($ext, $allowed_extensions, true)) {
            return new WP_Error(
                'bkic_invalid_image',
                'Dozvoljeni su samo JPG, PNG, WEBP i GIF.',
                ['status' => 400]
            );
        }

        // 🔥 EKSTRA SIKKERHED (WordPress egen validering)
        $filetype = wp_check_filetype_and_ext(
            $file['tmp_name'],
            $file['name']
        );

        if (empty($filetype['ext']) || empty($filetype['type'])) {
            return new WP_Error(
                'bkic_invalid_file',
                'Nevažeći tip datoteke.',
                ['status' => 400]
            );
        }

        // Upload
        $attachment_id = media_handle_upload('image', 0);

        if (is_wp_error($attachment_id)) {
            return new WP_Error(
                'bkic_upload_failed',
                $attachment_id->get_error_message(),
                ['status' => 400]
            );
        }

        $url = wp_get_attachment_url($attachment_id);

        return rest_ensure_response([
            'success' => true,
            'message' => 'Slika je uspješno uploadovana.',
            'data'    => [
                'url' => $url,
                'id'  => $attachment_id,
            ],
            'url' => $url, // ekstra kompatibilitet til Flutter
            'id'  => $attachment_id,
        ]);
    }
}