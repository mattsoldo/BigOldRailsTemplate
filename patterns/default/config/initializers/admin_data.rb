# NOTE: Regardless of these settings, admin_data is always usable in development (localhost:3000/admin_data)
AdminDataConfig.set = {
  :is_allowed_to_view => lambda {|controller| controller.send('view_admin_data?') },
  :is_allowed_to_update => lambda {|controller| controller.send('edit_admin_data?') },
  :feed_authentication_user_id => "#{admin_data_user_id}",
  :feed_authentication_password => "#{admin_data_password}" 
}

#{admin_data_xss_block}
