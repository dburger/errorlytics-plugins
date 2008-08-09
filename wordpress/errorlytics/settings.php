<div class="wrap">
    <h2>Errorlytics Settings</h2>

    <form method="post" action="options.php">
        <?php wp_nonce_field('update-options'); ?>
        <input type="hidden" name="action" value="update" />
        <input type="hidden" name="page_options" value="<?php echo ERRORLYTICS_URL_OPT_NAME . ',' . ERRORLYTICS_SECRET_KEY_OPT_NAME . ',' . ERRORLYTICS_ACCOUNT_ID_OPT_NAME . ',' . ERRORLYTICS_WEBSITE_ID_OPT_NAME; ?>" />

        <table class="form-table">
            <tr>
                <th scope="row"><label for="<?php echo ERRORLYTICS_URL_OPT_NAME ?>">Errorlytics URL</label></th>
                <td><input type="text" id="<?php echo ERRORLYTICS_URL_OPT_NAME ?>" name="<?php echo ERRORLYTICS_URL_OPT_NAME ?>" value="<?php echo $errorlytics_url; ?>" /></td>
            </tr>
            <tr>
                <th scope="row"><label for="<?php echo ERRORLYTICS_SECRET_KEY_OPT_NAME ?>">Errorlytics Secret Key</label></th>
                <td><input type="text" id="<?php echo ERRORLYTICS_SECRET_KEY_OPT_NAME ?>" name="<?php echo ERRORLYTICS_SECRET_KEY_OPT_NAME ?>" value="<?php echo get_option(ERRORLYTICS_SECRET_KEY_OPT_NAME); ?>" /></td>
            </tr>
            <tr>
                <th scope="row"><label for="<?php echo ERRORLYTICS_ACCOUNT_ID_OPT_NAME ?>">Errorlytics Account ID</label></th>
                <td><input type="text" id="<?php echo ERRORLYTICS_ACCOUNT_ID_OPT_NAME ?>" name="<?php echo ERRORLYTICS_ACCOUNT_ID_OPT_NAME ?>" value="<?php echo get_option(ERRORLYTICS_ACCOUNT_ID_OPT_NAME); ?>" /></td>
            </tr>
            <tr>
                <th scope="row"><label for="<?php echo ERRORLYTICS_WEBSITE_ID_OPT_NAME ?>">Errorlytics Website ID</label></th>
                <td><input type="text" id="<?php echo ERRORLYTICS_WEBSITE_ID_OPT_NAME ?>" name="<?php echo ERRORLYTICS_WEBSITE_ID_OPT_NAME ?>" value="<?php echo get_option(ERRORLYTICS_WEBSITE_ID_OPT_NAME); ?>" /></td>
            </tr>
        </table>

        <p class="submit">
            <input type="submit" name="Submit" value="<?php _e('Save Changes') ?>" />
        </p>
    </form>
</div>
