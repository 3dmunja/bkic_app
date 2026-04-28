/* ============================================
   BKIC MEMBERSHIP SYSTEM – FINAL VERSION
   Produkt ID: 249 (Godišnja članarina)
============================================ */

define('BKIC_PRODUCT_ID_YEARLY', 249);

/* ===== Helper: Parse år string (2009-2015,2017) ===== */
function bkic_parse_years($input){
    $years = [];
    $input = str_replace(' ', '', $input);

    foreach(explode(',', $input) as $part){
        if(strpos($part,'-') !== false){
            list($start,$end)=explode('-',$part);
            for($y=(int)$start;$y<=(int)$end;$y++){
                $years[]=$y;
            }
        }else{
            if(is_numeric($part)){
                $years[]=(int)$part;
            }
        }
    }

    $years=array_unique($years);
    sort($years);
    return $years;
}

/* ===== Shortcode ===== */
add_shortcode('bkic_membership_status','bkic_membership_status_shortcode');
function bkic_membership_status_shortcode(){

    if(!is_user_logged_in()) return '';

    $user_id=get_current_user_id();
    $member_since=get_user_meta($user_id,'bkic_member_since',true);
    $paid_string=get_user_meta($user_id,'bkic_paid_years',true);

    // Hvis der endnu ikke findes nogen data
    if (empty($member_since) && empty($paid_string)) {
        return '<div class="bkic-status-box"><p>Još nema evidentiranih podataka.</p></div>';
    }

    if(!$member_since) $member_since=2009;

    $paid_years=$paid_string?bkic_parse_years($paid_string):[];

    $current_year=date('Y');

    $all_years=[];
    for($y=$member_since;$y<=$current_year;$y++){
        $all_years[]=$y;
    }

    $missing_years=array_diff($all_years,$paid_years);
    sort($missing_years);

    ob_start();
    ?>

    <div class="bkic-status-box">

        <h3>Status članstva <?php echo $current_year; ?></h3>

        <?php if(empty($paid_years)): ?>
            <div class="bkic-warning">
                ⚠ Još nema evidentirane uplate na profilu.
            </div>
        <?php endif; ?>

        <?php if(in_array($current_year,$missing_years)): ?>
            <div class="bkic-warning">
                ⚠ Nije evidentirana uplata za <?php echo $current_year; ?>
            </div>
        <?php else: ?>
            <div class="bkic-success">
                ✔ Uplata za <?php echo $current_year; ?> je evidentirana
            </div>
        <?php endif; ?>

        <?php if(!empty($missing_years)): ?>
        <div class="bkic-payment-box">

            <form method="post">

                <label><strong>Odaberi godinu:</strong></label>

                <select name="bkic_selected_year" required>
                    <?php foreach($missing_years as $year): ?>
                        <option value="<?php echo esc_attr($year); ?>">
                            <?php echo esc_html($year); ?>
                        </option>
                    <?php endforeach; ?>
                </select>

                <br><br>

                <button type="submit" name="bkic_pay_year">
                    Plati izabranu godinu
                </button>

            </form>

            <details>
                <summary>Nedostaje: <?php echo count($missing_years); ?></summary>
                <p><?php echo implode(', ',$missing_years); ?></p>
            </details>

        </div>
        <?php endif; ?>

        <div style="margin-top:15px;">
            <strong>Član od:</strong> <?php echo $member_since; ?><br>
            <strong>Plaćeno (historik):</strong>
            <?php echo !empty($paid_years)?implode(', ',$paid_years):'—'; ?><br>
            <strong>Nedostaje:</strong>
            <?php echo !empty($missing_years)?implode(', ',$missing_years):'—'; ?>
        </div>

    </div>

    <?php
    return ob_get_clean();
}

/* ===== Add to cart ===== */
add_action('init','bkic_add_year_to_cart');
function bkic_add_year_to_cart(){

    if(isset($_POST['bkic_pay_year']) && isset($_POST['bkic_selected_year'])){

        $year=intval($_POST['bkic_selected_year']);

        WC()->cart->add_to_cart(
            BKIC_PRODUCT_ID_YEARLY,
            1,
            0,
            [],
            ['membership_year'=>$year]
        );

        wp_redirect(wc_get_cart_url());
        exit;
    }
}

/* ===== Show year in cart ===== */
add_filter('woocommerce_get_item_data','bkic_display_year_in_cart',10,2);
function bkic_display_year_in_cart($item_data,$cart_item){

    if(isset($cart_item['membership_year'])){
        $item_data[]=[
            'key'=>'Godina članarine',
            'value'=>$cart_item['membership_year']
        ];
    }

    return $item_data;
}

/* ===== Save year on order ===== */
add_action('woocommerce_checkout_create_order_line_item','bkic_save_year_to_order',10,4);
function bkic_save_year_to_order($item,$cart_item_key,$values,$order){

    if(isset($values['membership_year'])){
        $item->add_meta_data('Godina članarine',$values['membership_year'],true);
    }
}

/* ===== Auto update paid years when order completed ===== */
add_action('woocommerce_order_status_completed','bkic_update_paid_years');
function bkic_update_paid_years($order_id){

    $order=wc_get_order($order_id);
    $user_id=$order->get_user_id();

    if(!$user_id) return;

    foreach($order->get_items() as $item){

        if($item->get_product_id()==BKIC_PRODUCT_ID_YEARLY){

            $year=$item->get_meta('Godina članarine');
            if($year){

                $existing=get_user_meta($user_id,'bkic_paid_years',true);
                $years=$existing?bkic_parse_years($existing):[];

                $years[]=(int)$year;
                $years=array_unique($years);
                sort($years);

                update_user_meta($user_id,'bkic_paid_years',implode(',',$years));
            }
        }
    }
}