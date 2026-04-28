/**
 * BKIC: Giv medlemsrolle + udløb når produkt ID 249 er købt.
 * + Cap til Vijesti + body class + REST-lås på /bkic/v1/vijesti
 * + Manuelle medlemsfelter + shortcode til medlemsstatus
 */

/** 0) Opret rolle hvis den ikke findes + sikre cap findes */
add_action('init', function () {
    if (!get_role('bkic_member')) {
        add_role(
            'bkic_member',
            'BKIC Member',
            array(
                'read' => true,
                'bkic_view_vijesti' => true,
            )
        );
    } else {
        $role = get_role('bkic_member');
        if ($role && !$role->has_cap('bkic_view_vijesti')) {
            $role->add_cap('bkic_view_vijesti');
        }
    }
});

/** Hjælper: Tjek om bruger er aktivt medlem (rolle + ikke udløbet) */
function bkic_is_active_member($user_id = null) {
    $user_id = $user_id ?: get_current_user_id();
    if (!$user_id) return false;

    $user = get_userdata($user_id);
    if (!$user) return false;

    if (empty($user->roles) || !in_array('bkic_member', (array) $user->roles, true)) {
        return false;
    }

    $expires = (int) get_user_meta($user_id, 'bkic_member_expires', true);
    if ($expires && $expires <= time()) {
        return false;
    }

    return true;
}

/** 1) Når ordre er betalt/igang, giv rolle + sæt udløb */
add_action('woocommerce_order_status_completed', 'bkic_grant_membership_on_paid');
add_action('woocommerce_order_status_processing', 'bkic_grant_membership_on_paid');

function bkic_grant_membership_on_paid($order_id) {
    if (!$order_id) return;

    $order = wc_get_order($order_id);
    if (!$order) return;

    $user_id = $order->get_user_id();
    if (!$user_id) return;

    $target_product_id = 249;

    foreach ($order->get_items() as $item) {
        $pid = $item->get_product_id();

        if ((int) $pid === (int) $target_product_id) {
            $user = new WP_User($user_id);
            $user->add_role('bkic_member');

            // Smart fornyelse: forlæng fra eksisterende udløb hvis det stadig er aktivt
            $current_expires = (int) get_user_meta($user_id, 'bkic_member_expires', true);
            $base = ($current_expires && $current_expires > time()) ? $current_expires : time();
            $expires = strtotime('+1 year', $base);
            update_user_meta($user_id, 'bkic_member_expires', $expires);

            update_user_meta($user_id, 'bkic_member_last_order', (int) $order_id);

            break;
        }
    }
}

/** 2) Dagligt tjek: fjern rolle når udløbet */
add_action('bkic_daily_membership_check', 'bkic_daily_membership_check_run');

function bkic_daily_membership_check_run() {
    $users = get_users(array(
        'role'   => 'bkic_member',
        'fields' => array('ID')
    ));

    $now = time();

    foreach ($users as $u) {
        $expires = (int) get_user_meta($u->ID, 'bkic_member_expires', true);
        if (!$expires) continue;

        if ($expires <= $now) {
            $user = new WP_User($u->ID);
            $user->remove_role('bkic_member');
        }
    }
}

/** 3) Sørg for at cron-jobbet findes (kører 1 gang dagligt) */
add_action('init', function () {
    if (!wp_next_scheduled('bkic_daily_membership_check')) {
        wp_schedule_event(time() + 300, 'daily', 'bkic_daily_membership_check');
    }
});

/** 4) Shortcode til at vise udløbsdato til brugeren */
add_shortcode('bkic_member_expires', function () {
    if (!is_user_logged_in()) return '';

    $user_id = get_current_user_id();
    $expires = (int) get_user_meta($user_id, 'bkic_member_expires', true);
    if (!$expires) return 'Ingen udløbsdato registreret.';

    return date_i18n('d-m-Y', $expires);
});

/** 5) Body class: giver 'bkic-member' til alle loggede ind brugere */
add_filter('body_class', function ($classes) {
    if (is_user_logged_in()) {
        $classes[] = 'bkic-member';
    }
    return $classes;
});

/**
 * 5.4) Hjælper: prøv at autentificere frontend cookie manuelt for udvalgte REST routes
 */
function bkic_try_cookie_auth_for_rest() {
    if (is_user_logged_in()) {
        return;
    }

    if (empty($_COOKIE[LOGGED_IN_COOKIE])) {
        return;
    }

    $user_id = wp_validate_auth_cookie($_COOKIE[LOGGED_IN_COOKIE], 'logged_in');
    if (!$user_id) {
        return;
    }

    wp_set_current_user($user_id);
}

/**
 * 5.5) Tillad cookie-login uden nonce for:
 * - /bkic/v1/vijesti
 * - /bkicsaff/v1/me/membership
 */
add_filter('rest_authentication_errors', function ($result) {
    $uri = $_SERVER['REQUEST_URI'] ?? '';

    $is_bkic_vijesti = strpos($uri, '/wp-json/bkic/v1/vijesti') !== false;
    $is_bkic_membership = strpos($uri, '/wp-json/bkicsaff/v1/me/membership') !== false;

    if (!$is_bkic_vijesti && !$is_bkic_membership) {
        return $result;
    }

    bkic_try_cookie_auth_for_rest();

    if (!is_wp_error($result)) {
        return $result;
    }

    $code = $result->get_error_code();

    if ($code === 'rest_cookie_invalid_nonce' || $code === 'rest_not_logged_in') {
        return null;
    }

    return $result;
}, 99);

/** 6) Lås REST endpoints */
add_filter('rest_pre_dispatch', function ($result, $server, $request) {
    $route = $request->get_route();

    $is_bkic_vijesti = strpos($route, '/bkic/v1/vijesti') === 0;
    $is_bkic_membership = strpos($route, '/bkicsaff/v1/me/membership') === 0;

    if (!$is_bkic_vijesti && !$is_bkic_membership) {
        return $result;
    }

    bkic_try_cookie_auth_for_rest();

    if (!is_user_logged_in()) {
        return new WP_Error('bkic_login_required', 'Login required', array('status' => 401));
    }

    if ($is_bkic_vijesti && !bkic_is_active_member(get_current_user_id())) {
        return new WP_Error('bkic_forbidden', 'Members only', array('status' => 403));
    }

    return $result;
}, 10, 3);

// BKIC - AJAX vijesti (kun for medlemmer)
add_action('wp_ajax_bkic_get_vijesti', 'bkic_ajax_get_vijesti');

function bkic_ajax_get_vijesti() {
    if (!is_user_logged_in()) {
        wp_send_json_error(['message' => 'Login required'], 401);
    }

    $user = wp_get_current_user();
    if (!in_array('bkic_member', (array) $user->roles, true)) {
        wp_send_json_error(['message' => 'Not member'], 403);
    }

    $args = [
        'post_type'      => 'vijesti',
        'posts_per_page' => 20,
        'post_status'    => 'publish'
    ];

    $query = new WP_Query($args);
    $data = [];

    foreach ($query->posts as $post) {
        $data[] = [
            'title' => $post->post_title,
            'text'  => wp_strip_all_tags($post->post_content),
            'start' => get_post_meta($post->ID, 'start', true),
            'end'   => get_post_meta($post->ID, 'end', true),
        ];
    }

    wp_send_json($data);
}

/** 7) Manuelle felter på brugerprofil */
add_action('show_user_profile', 'bkic_membership_manual_fields');
add_action('edit_user_profile', 'bkic_membership_manual_fields');

function bkic_membership_manual_fields($user) {
    $member_since = get_user_meta($user->ID, 'bkic_member_since', true);
    $paid_years   = get_user_meta($user->ID, 'bkic_paid_years', true);
    ?>
    <h2>BKIC medlemsstatus</h2>
    <table class="form-table" role="presentation">
        <tr>
            <th><label for="bkic_member_since">Član od / Medlem siden</label></th>
            <td>
                <input type="number"
                       name="bkic_member_since"
                       id="bkic_member_since"
                       value="<?php echo esc_attr($member_since); ?>"
                       class="regular-text"
                       min="1900"
                       max="2100">
                <p class="description">Eksempel: 2020</p>
            </td>
        </tr>
        <tr>
            <th><label for="bkic_paid_years">Plaćeno (historik) / Betalte år</label></th>
            <td>
                <input type="text"
                       name="bkic_paid_years"
                       id="bkic_paid_years"
                       value="<?php echo esc_attr($paid_years); ?>"
                       class="regular-text">
                <p class="description">Eksempel: 2020, 2022, 2026</p>
            </td>
        </tr>
    </table>
    <?php
}

add_action('personal_options_update', 'bkic_save_membership_manual_fields');
add_action('edit_user_profile_update', 'bkic_save_membership_manual_fields');

function bkic_save_membership_manual_fields($user_id) {
    if (!current_user_can('edit_user', $user_id)) {
        return;
    }

    if (isset($_POST['bkic_member_since'])) {
        update_user_meta($user_id, 'bkic_member_since', sanitize_text_field($_POST['bkic_member_since']));
    }

    if (isset($_POST['bkic_paid_years'])) {
        update_user_meta($user_id, 'bkic_paid_years', sanitize_text_field($_POST['bkic_paid_years']));
    }
}

/** 8) Hjælper: Parse år-liste fra tekst */
function bkic_parse_year_list($value) {
    $value = (string) $value;
    if ($value === '') return [];

    $parts = preg_split('/[\s,;]+/', $value);
    $years = [];

    foreach ($parts as $part) {
        $year = (int) trim($part);
        if ($year >= 1900 && $year <= 2100) {
            $years[] = $year;
        }
    }

    $years = array_values(array_unique($years));
    sort($years);

    return $years;
}

/** 9) Shortcode: [bkic_membership_status] */
add_shortcode('bkic_membership_status', function () {
    if (!is_user_logged_in()) {
        return '';
    }

    $user_id      = get_current_user_id();
    $current_year = (int) date('Y');

    $member_since_raw = get_user_meta($user_id, 'bkic_member_since', true);
    $paid_years_raw   = get_user_meta($user_id, 'bkic_paid_years', true);

    $member_since = (int) $member_since_raw;
    $paid_years   = bkic_parse_year_list($paid_years_raw);

    if ($member_since < 1900 || $member_since > 2100) {
        $member_since = $paid_years ? min($paid_years) : $current_year;
    }

    $all_years = range($member_since, $current_year);
    $missing_years = array_values(array_diff($all_years, $paid_years));
    $missing_count = count($missing_years);
    $is_current_paid = in_array($current_year, $paid_years, true);

    $selected_year = !empty($missing_years) ? min($missing_years) : $current_year;
    $product_id = 249;
    $pay_url = add_query_arg('add-to-cart', $product_id, wc_get_cart_url());

    ob_start();
    ?>
    <div class="bkic-membership-box">
        <h3 style="margin-top:0;">Status članstva <?php echo esc_html($current_year); ?></h3>

        <p style="margin:0 0 14px 0;">
            <?php if ($is_current_paid): ?>
                ✔ Uplata za <?php echo esc_html($current_year); ?> je evidentirana
            <?php else: ?>
                ✖ Uplata za <?php echo esc_html($current_year); ?> nije evidentirana
            <?php endif; ?>
        </p>

        <?php if (!empty($missing_years)): ?>
            <form method="get" action="<?php echo esc_url(wc_get_cart_url()); ?>" style="margin:0 0 18px 0;">
                <input type="hidden" name="add-to-cart" value="<?php echo esc_attr($product_id); ?>">

                <label for="bkic_year_select" style="display:block; font-weight:700; margin-bottom:8px;">
                    Odaberi godinu:
                </label>

                <select name="bkic_year" id="bkic_year_select" style="min-width:220px; padding:10px; margin-bottom:12px;">
                    <?php foreach ($missing_years as $year): ?>
                        <option value="<?php echo esc_attr($year); ?>" <?php selected($year, $selected_year); ?>>
                            <?php echo esc_html($year); ?>
                        </option>
                    <?php endforeach; ?>
                </select>

                <br>

                <button type="submit" style="padding:12px 20px; font-weight:700; cursor:pointer;">
                    Plati izabranu godinu
                </button>
            </form>

            <details style="margin:0 0 18px 0;">
                <summary style="cursor:pointer; font-weight:700;">Nedostaje: <?php echo esc_html($missing_count); ?></summary>
                <div style="margin-top:10px;">
                    <?php echo esc_html(implode(', ', $missing_years)); ?>
                </div>
            </details>
        <?php endif; ?>

        <p style="margin:10px 0 0 0;"><strong>Član od:</strong> <?php echo esc_html($member_since); ?></p>
        <p style="margin:10px 0 0 0;"><strong>Plaćeno (historik):</strong>
            <?php echo !empty($paid_years) ? esc_html(implode(', ', $paid_years)) : '—'; ?>
        </p>
        <p style="margin:10px 0 0 0;"><strong>Nedostaje:</strong>
            <?php echo !empty($missing_years) ? esc_html(implode(', ', $missing_years)) : '—'; ?>
        </p>
    </div>
    <?php
    return ob_get_clean();
});

/** 10) Shortcode helpers til links */
add_shortcode('bkic_profile_url', function () {
    if (!is_user_logged_in()) return '';
    return esc_url(get_edit_profile_url(get_current_user_id()));
});

add_shortcode('bkic_logout_url', function () {
    return esc_url(wp_logout_url(home_url('/')));
});

/** 11) REST endpoint til app: medlemsdata */
add_action('rest_api_init', function () {
    register_rest_route('bkicsaff/v1', '/me/membership', array(
        'methods'  => 'GET',
        'callback' => 'bkic_rest_get_membership',
        'permission_callback' => '__return_true',
    ));
});

function bkic_rest_get_membership(WP_REST_Request $request) {
    bkic_try_cookie_auth_for_rest();

    $user_id = get_current_user_id();

    if (!$user_id) {
        return new WP_Error(
            'bkic_not_logged_in',
            'Korisnik nije prijavljen.',
            array('status' => 401)
        );
    }

    $current_year = (int) date('Y');

    $member_since_raw = get_user_meta($user_id, 'bkic_member_since', true);
    $paid_years_raw   = get_user_meta($user_id, 'bkic_paid_years', true);
    $expires_raw      = get_user_meta($user_id, 'bkic_member_expires', true);

    $member_since = (int) $member_since_raw;
    $paid_years   = bkic_parse_year_list($paid_years_raw);
    $expires      = (int) $expires_raw;

    if ($member_since < 1900 || $member_since > 2100) {
        $member_since = !empty($paid_years) ? min($paid_years) : $current_year;
    }

    $all_years = range($member_since, $current_year);
    $missing_years = array_values(array_diff($all_years, $paid_years));
    sort($missing_years);

    $missing_count = count($missing_years);
    $is_current_paid = in_array($current_year, $paid_years, true);
    $selected_year = !empty($missing_years) ? min($missing_years) : $current_year;

    $product_id = 249;
    $pay_url = add_query_arg(array(
        'add-to-cart' => $product_id,
        'bkic_year'   => $selected_year,
    ), wc_get_cart_url());

    $status = bkic_is_active_member($user_id) ? 'active' : 'inactive';

    $warning = $is_current_paid
        ? 'Uplata za ' . $current_year . ' je evidentirana'
        : 'Nije evidentirana uplata za ' . $current_year;

    return rest_ensure_response(array(
        'success' => true,
        'data' => array(
            'status' => $status,
            'type' => 'Član',
            'valid_until' => $expires ? date_i18n('d-m-Y', $expires) : '',
            'member_since' => $member_since,
            'paid_years' => array_values($paid_years),
            'missing_years' => array_values($missing_years),
            'missing_count' => $missing_count,
            'warning' => $warning,
            'current_year' => $current_year,
            'selected_year' => $selected_year,
            'available_years' => array_values($missing_years),
            'is_current_paid' => $is_current_paid,
            'pay_url' => $pay_url,
        ),
    ));
}