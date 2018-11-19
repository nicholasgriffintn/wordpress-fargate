FROM php:7.2-apache
LABEL maintainer="Nicholas Griffin <nicholas.griffin@example.com>"

RUN a2enmod rewrite

# install the PHP extensions we need
RUN apt-get update && apt-get install -y libpng-dev libjpeg-dev unzip && rm -rf /var/lib/apt/lists/* \
	&& docker-php-ext-configure gd --with-png-dir=/usr --with-jpeg-dir=/usr \
	&& docker-php-ext-install gd
RUN docker-php-ext-install mysqli

# install the awscli
RUN apt-get update -q
RUN DEBIAN_FRONTEND=noninteractive apt-get install -qy python-pip groff-base
RUN pip install awscli

VOLUME /var/www/html

ENV WORDPRESS_VERSION 4.9.8
ENV WORDPRESS_UPSTREAM_VERSION 4.9.8
ENV WORDPRESS_SHA1 fcfd6260c7de942ba85e0bbf0db7987d4cf3ec26

# upstream tarballs include ./wordpress/ so this gives us /usr/src/wordpress
RUN curl -o wordpress.tar.gz -SL https://en-gb.wordpress.org/wordpress-${WORDPRESS_UPSTREAM_VERSION}-en_GB.tar.gz \
	&& echo "$WORDPRESS_SHA1 *wordpress.tar.gz" | sha1sum -c - \
	&& tar -xzf wordpress.tar.gz -C /usr/src/ \
	&& rm wordpress.tar.gz \
	&& chown -R www-data:www-data /usr/src/wordpress

# Install Wordpress CLI
RUN curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar \
    && php wp-cli.phar --info \
    && chmod +x wp-cli.phar \
		&& mv wp-cli.phar /usr/local/bin/wp

# Add sunrise
RUN curl -o sunrise.zip https://bitbucket.org/examplesites/sunrise/raw/22da1b2e1c4d6727c8feffaeadb080b33f8fd350/sunrise.php.V3.zip \
  && unzip sunrise.zip -d /usr/src/wordpress/wp-content \
	&& rm sunrise.zip

# Download plugins
ENV NINJA_FORMS_VERSION 3.3.18
RUN curl -o ninja-forms.zip https://downloads.wordpress.org/plugin/ninja-forms.${NINJA_FORMS_VERSION}.zip \
  && unzip ninja-forms.zip -d /usr/src/wordpress/wp-content/plugins \
	&& rm ninja-forms.zip

ENV USER_ROLE_VERSION 4.47
RUN curl -o user-role-editor.zip https://downloads.wordpress.org/plugin/user-role-editor.${USER_ROLE_VERSION}.zip \
  && unzip user-role-editor.zip -d /usr/src/wordpress/wp-content/plugins \
	&& rm user-role-editor.zip

ENV YOAST_SEO_VERSION 9.1
RUN curl -o yoast-seo.zip https://downloads.wordpress.org/plugin/wordpress-seo.${YOAST_SEO_VERSION}.zip \
  && unzip yoast-seo.zip -d /usr/src/wordpress/wp-content/plugins \
	&& rm yoast-seo.zip

ENV S3_CLOUDFRONT_VERSION 2.0
RUN curl -o amazon-s3-and-cloudfront.zip https://downloads.wordpress.org/plugin/amazon-s3-and-cloudfront.${S3_CLOUDFRONT_VERSION}.zip \
  && unzip amazon-s3-and-cloudfront.zip -d /usr/src/wordpress/wp-content/plugins \
	&& rm amazon-s3-and-cloudfront.zip

ENV ACTIVITY_LOG_VERSION 2.5.1
RUN curl -o activity-log.zip https://downloads.wordpress.org/plugin/aryo-activity-log.${ACTIVITY_LOG_VERSION}.zip \
  && unzip activity-log.zip -d /usr/src/wordpress/wp-content/plugins \
	&& rm activity-log.zip

ENV CLOUDFLARE_VERSION 3.3.2
RUN curl -o cloudflare.zip https://downloads.wordpress.org/plugin/cloudflare.${CLOUDFLARE_VERSION}.zip \
  && unzip cloudflare.zip -d /usr/src/wordpress/wp-content/plugins \
	&& rm cloudflare.zip

ENV REDIRECTION_VERSION 3.6.3
RUN curl -o redirection.zip https://downloads.wordpress.org/plugin/redirection.${REDIRECTION_VERSION}.zip \
  && unzip redirection.zip -d /usr/src/wordpress/wp-content/plugins \
	&& rm redirection.zip

ENV GTM_VERSION 1.9
RUN curl -o gtm.zip https://downloads.wordpress.org/plugin/duracelltomi-google-tag-manager.${GTM_VERSION}.zip \
  && unzip gtm.zip -d /usr/src/wordpress/wp-content/plugins \
	&& rm gtm.zip

ENV ACF_YOAST_VERSION 2.1.0
RUN curl -o acf-yoast.zip https://downloads.wordpress.org/plugin/acf-content-analysis-for-yoast-seo.${ACF_YOAST_VERSION}.zip \
  && unzip acf-yoast.zip -d /usr/src/wordpress/wp-content/plugins \
	&& rm acf-yoast.zip

RUN curl -o app-password.zip https://downloads.wordpress.org/plugin/application-passwords.zip \
  && unzip app-password.zip -d /usr/src/wordpress/wp-content/plugins \
	&& rm app-password.zip

ENV ELEMENTOR_VERSION 2.3.2
RUN curl -o elementor.zip https://downloads.wordpress.org/plugin/elementor.${ELEMENTOR_VERSION}.zip \
  && unzip elementor.zip -d /usr/src/wordpress/wp-content/plugins \
	&& rm elementor.zip

ENV WORD_HTTPS_VERSION 3.4.0
RUN curl -o word-https.zip https://downloads.wordpress.org/plugin/wordpress-https.${WORD_HTTPS_VERSION}.zip \
  && unzip word-https.zip -d /usr/src/wordpress/wp-content/plugins \
	&& rm word-https.zip

# RUN curl -o mercator.zip https://bitbucket.org/examplesites/mercator/raw/55af71f7120c5c5978c7327737698904f7c02cec/mercator.zip \
#   && unzip mercator.zip -d /usr/src/wordpress/wp-content/mu-plugins \
# 	&& rm mercator.zip

# These will need to come from the git
RUN curl -o migrate-db-pro.zip https://bitbucket.org/examplesites/wp-migrate-db/raw/77d9a80a9ddb1d7bcf5e3e95043605ca40b89ded/1.8.3/wp-migrate-db-pro-1.8.3.zip \
  && unzip migrate-db-pro.zip -d /usr/src/wordpress/wp-content/plugins \
	&& rm migrate-db-pro.zip

RUN curl -o migrate-db-pro-cli.zip https://bitbucket.org/examplesites/wp-migrate-db/raw/77d9a80a9ddb1d7bcf5e3e95043605ca40b89ded/1.8.3/wp-migrate-db-pro-cli-1.3.3.zip \
  && unzip migrate-db-pro-cli.zip -d /usr/src/wordpress/wp-content/plugins \
	&& rm migrate-db-pro-cli.zip

RUN curl -o migrate-db-pro-multisite.zip https://bitbucket.org/examplesites/wp-migrate-db/raw/77d9a80a9ddb1d7bcf5e3e95043605ca40b89ded/1.8.3/wp-migrate-db-pro-multisite-tools-1.2.1.zip \
  && unzip migrate-db-pro-multisite.zip -d /usr/src/wordpress/wp-content/plugins \
	&& rm migrate-db-pro-multisite.zip

RUN curl -o acf.zip https://bitbucket.org/examplesites/advanced-custom-fields/raw/07833b8077335427819a6593bbdbeb6b1f1a725a/5.7.3/advanced-custom-fields-pro-5.7.3.zip \
  && unzip acf.zip -d /usr/src/wordpress/wp-content/plugins \
	&& rm acf.zip

RUN curl -o acf-ext.zip https://bitbucket.org/examplesites/acf-ext/raw/a0777116d6e9ae2b2cb1639c3c5b1bfda5355ef6/acf-quick-edit-fields.zip \
  && unzip acf-ext.zip -d /usr/src/wordpress/wp-content/plugins \
	&& rm acf-ext.zip

RUN curl -o vfsf.zip https://bitbucket.org/examplesites/wordpress-smartfeed/raw/992d5fb32f32b996e43794aa841f0750ce7a2798/_releases/vfsf_v1.1.1.zip \
  && unzip vfsf.zip -d /usr/src/wordpress/wp-content/plugins \
	&& rm vfsf.zip

RUN curl -o defender.zip https://bitbucket.org/examplesites/wpmu-pluginns/raw/94f190b3aa8a4c2f1968b09306dad98900ca9b41/wp-defender.zip \
  && unzip defender.zip -d /usr/src/wordpress/wp-content/plugins \
	&& rm defender.zip

RUN curl -o hummingbbird.zip https://bitbucket.org/examplesites/wpmu-pluginns/raw/94f190b3aa8a4c2f1968b09306dad98900ca9b41/wp-hummingbird.zip \
  && unzip hummingbbird.zip -d /usr/src/wordpress/wp-content/plugins \
	&& rm hummingbbird.zip

RUN curl -o smush.zip https://bitbucket.org/examplesites/wpmu-pluginns/raw/94f190b3aa8a4c2f1968b09306dad98900ca9b41/wp-smush-pro.zip \
  && unzip smush.zip -d /usr/src/wordpress/wp-content/plugins \
	&& rm smush.zip

RUN curl -o wpmudash.zip https://bitbucket.org/examplesites/wpmu-pluginns/raw/94f190b3aa8a4c2f1968b09306dad98900ca9b41/wpmu-dev-dashboard.zip \
  && unzip wpmudash.zip -d /usr/src/wordpress/wp-content/plugins \
	&& rm wpmudash.zip

RUN curl -o branding.zip https://bitbucket.org/examplesites/wpmu-pluginns/raw/94f190b3aa8a4c2f1968b09306dad98900ca9b41/ultimate-branding.zip \
  && unzip branding.zip -d /usr/src/wordpress/wp-content/plugins \
	&& rm branding.zip

RUN curl -o example.zip https://bitbucket.org/examplesites/sage/raw/ac2995e8c83101bf6bb5473914b8266f52ee050a/versions/example-V2.zip \
  && unzip example.zip -d /usr/src/wordpress/wp-content/themes/example \
	&& rm example.zip

COPY docker-entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
CMD ["apache2-foreground"]
