module Xsendfile

  # Define options for this plugin via the <tt>configure</tt> method
  # in your application manifest (none are needed by default):
  #
  #   configure(:xsendfile => {:x_send_file_path => '/some/absolute/path'})
  #
  # Then call the recipe:
  #
  #  recipe :xsendfile
  def xsendfile(options = {})
    package 'apache2-threaded-dev', :ensure => :installed

    # --no-check-certificate is needed because GitHub has SSL turned on all the time
    # but wget doesn't understand the wildcard SSL certificate they use (*.github.com)
    exec 'install_xsendfile',
      :cwd => '/tmp',
      :command => [
        'wget https://raw.githubusercontent.com/nmaier/mod_xsendfile/master/mod_xsendfile.c --no-check-certificate',
        'apxs2 -ci mod_xsendfile.c'
      ].join(' && '),
      :require => package('apache2-threaded-dev'),
      :before => service('apache2'),
      :creates => '/usr/lib/apache2/modules/mod_xsendfile.so'

    conf = ["XSendFile #{ options[:x_send_file] || 'on'}"]
    conf << "XSendFileIgnoreEtag #{options[:x_send_file_ignore_etag] || 'off'}"
    conf << "XSendFileIgnoreLastModified #{options[:x_send_file_ignore_last_modified] || 'off'}"
    conf << "XSendFilePath #{options[:x_send_file_path]}" if options[:x_send_file_path]

    file '/etc/apache2/mods-available/xsendfile.conf',
      :alias => 'xsendfile_conf',
      :content => conf.join("\n"),
      :mode => '644',
      :notify => service('apache2'),
      :require => package('apache2-threaded-dev')

    file '/etc/apache2/mods-available/xsendfile.load',
      :alias => 'load_xsendfile',
      :content => 'LoadModule xsendfile_module /usr/lib/apache2/modules/mod_xsendfile.so',
      :mode => '644',
      :require => file('xsendfile_conf'),
      :notify => service('apache2'),
      :require => package('apache2-threaded-dev')

   a2enmod 'xsendfile', :require => file('load_xsendfile')
  end

end
