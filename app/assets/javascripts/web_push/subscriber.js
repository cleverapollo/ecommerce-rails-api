/**
 * Конструктор подписка на веб пуши
 * @constructor
 */
function Subscriber(shop_id) {
	this.shop_id = shop_id;
	window.addEventListener("message", this.onMessage.bind(this));
	if( window.opener ) {
		window.opener.postMessage({type: 'load'}, '*')
	}
}

/**
 * Инициализация
 * @param {{enabled,safari_enabled}} options
 * @param {String} safari_url
 */
Subscriber.prototype.initialize = function(options, safari_url) {
	this.settings = options || null;
	this.safari_url = safari_url;

	//Инициализация и доступность в браузере
	this.available = false;
	this.registration = null;
	this.initialized = false;

	//enabled & supported
	if( this.popup && this.settings && this.enabled() && this.supported() ) {
		this.available = true;
		this.registerServiceWorker();
	} else {
		this.send({type: 'initialized'});
	}
};

/**
 * Получили сообщение с основного домена
 * @param e
 */
Subscriber.prototype.onMessage = function(e) {
	switch( e.data.type ) {
		case 'initialize':
			this.source = e.source;
			this.origin = e.origin;
			this.popup = e.data.popup || false;
			this.initialize(e.data.options, e.data.safari_url);
			break;
		case 'subscribe':
			this.subscribe();
			break;
	}
};

/**
 * @param data
 */
Subscriber.prototype.send = function(data) {
	this.source.postMessage(data, this.origin);
};

/**
 * Register service worker
 */
Subscriber.prototype.registerServiceWorker = function() {
	//Safari browser
	if( this.supportedSafari() ) {

		var data = window.safari.pushNotification.permission(this.settings.safari_id);
		this.initialized = true;
		this.registration = true;

		if( data.permission === 'granted' ) {
			this.subscription = true;
		}

		if( data.permission !== 'denied' ) {
			this.unsubscribed()
		}
	} else {

		//Register service worker
		navigator.serviceWorker.register('/assets/sw.js?shop_id=' + this.shop_id).then(function(reg) {
			this.initialized = true;
			this.registration = reg;
			this.subscribe();
		}.bind(this)).catch(function(error) {
			console.error('Service Worker error: ' + error);
		}.bind(this));

		//Get subscription data
		navigator.serviceWorker.ready.then(function(serviceWorkerRegistration) {
			serviceWorkerRegistration.pushManager.getSubscription().then(function(sub) {
				if( sub ) {
					this.subscription = sub;
					this.subscribed(sub);
				}
			}.bind(this))
		}.bind(this));
	}
};

/**
 * Запрашивает разрешение на отображение нотификаций
 */
Subscriber.prototype.requestPermission = function() {
	if( Notification.permission === 'granted' ) {
		this.send({type: 'popup'})
	} else {
		Notification.requestPermission().then(function(r) {
			if( r === 'granted' ) {
				this.send({type: 'granted'})
			} else if( r === 'denied') {
				this.send({type: 'close'})
			}
		}.bind(this))
	}
};

/**
 * Detect enabled web push in rees46 and available use on the host
 * @returns {boolean}
 */
Subscriber.prototype.enabled = function() {
	return this.settings && this.settings.enabled == true && (document.location.hostname == 'localhost' || document.location.protocol == 'https:')
};

/**
 * Web push supported in the browser
 * @returns {boolean}
 */
Subscriber.prototype.supported = function() {
	//Disable for IE
	if( navigator.userAgent.toLowerCase().indexOf('msie') != -1 ) {
		return false
	}

	// Are Notifications supported in the service worker?
	if( !(this.supportedSafari() && this.enabledSafari() || this.supportedOpera() || this.supportedWebkit()) ) {
		return false;
	}

	return Notification.permission !== 'denied';
};

Subscriber.prototype.subscribe = function() {
	if( this.isRegistered() ) {
		if( this.isSubscribed() ) {
			if( this.supportedSafari() ) {
				this.checkSafariRemotePermission(window.safari.pushNotification.permission(this.settings.safari_id))
			} else {
				this.subscribed(this.subscription)
			}
		} else {
			if( this.supportedSafari() ) {
				this.safariRequestPermission()
			} else {
				new Promise(function(resolve, reject) {
					if( Notification.permission === 'denied' ) {
						this.unsubscribed();
						return reject(new Error('Push messages are blocked.'));
					}

					if( Notification.permission === 'granted' ) {
						if( this.popup ) {
							return resolve();
						} else {
							this.send({type: 'popup'})
						}
					}

					if( Notification.permission === 'default' ) {
						Notification.requestPermission(function(result) {
							if( result == 'denied' ) {
								this.unsubscribed();
								return reject(new Error('Bad permission result'));
							}
							if( result === 'granted' ) {
								resolve();
							}
						}.bind(this));
					}
				}.bind(this))
					.then(function() {

						//Если открыли в окне
						if( this.popup ) {

							//Запускаем подписку
							this.registration.pushManager.subscribe({userVisibleOnly: true}).then(function(sub) {
								this.subscribed(sub);
							}.bind(this)).catch(window.close);
						} else {
							this.send({type: 'granted'})
						}
					}.bind(this))
					.catch(function() {
						if( this.popup ) {
							window.close()
						} else {
							this.send({type: 'close'})
						}
					}.bind(this));
			}
		}
	} else {
		this.requestPermission()
	}
};

/**
 * Check safari permission
 * @param {object} data
 */
Subscriber.prototype.checkSafariRemotePermission = function(data) {
	if( data.permission === 'default' ) {
		this.safariRequestPermission();
	} else if( data.permission === 'denied' ) {
		this.unsubscribed();
	} else if( data.permission === 'granted' ) {
		this.initialized = true;
		this.subscription = true;
		this.subscribed(JSON.stringify({browser: 'safari', token: data.deviceToken}))
	}
};

/**
 * Make request to safari
 */
Subscriber.prototype.safariRequestPermission = function() {
	// This is a new web service URL and its validity is unknown.
	window.safari.pushNotification.requestPermission(
		this.safari_url,
		this.settings.safari_id,
		{}, // Data that you choose to send to your server to help you identify the user.
		this.checkSafariRemotePermission.bind(this)
	);
};

/**
 * Подписались
 * @param {object} sub
 */
Subscriber.prototype.subscribed = function(sub) {
	this.subscription = sub;
	this.send({type: 'subscribed', token: JSON.stringify(sub.toJSON())});
	if( this.popup ) {
		window.close()
	}
};

/**
 * Отписались
 */
Subscriber.prototype.unsubscribed = function() {
	this.subscription = null;
	this.send({type: 'unsubscribed'});
};

/**
 * Is user registered for web push
 * @returns {boolean}
 */
Subscriber.prototype.isRegistered = function() {
	return this.initialized && this.registration != null
};

/**
 * User subscribed to web push and sent token to rees46
 * @returns {boolean}
 */
Subscriber.prototype.isSubscribed = function() {
	return this.subscription != null && this.status == 'accepted'
};

/**
 * Safari uploaded certificate to rees46
 */
Subscriber.prototype.enabledSafari = function() {
	return this.settings && this.settings.safari_enabled
};

/**
 * Web push supported in the Chrome, Firefox browsers
 * @returns {boolean}
 */
Subscriber.prototype.supportedWebkit = function() {
	return 'serviceWorker' in navigator && 'showNotification' in ServiceWorkerRegistration.prototype && 'PushManager' in window
};

/**
 * Web push supported in the Safari browser
 * @returns {boolean}
 */
Subscriber.prototype.supportedSafari = function() {
	return 'safari' in window && 'pushNotification' in window.safari
};

/**
 * Web push supported in the Opera browser
 * Note: opera is not work correctly pushManager.subscribe
 * @returns {boolean}
 */
Subscriber.prototype.supportedOpera = function() {
	return !(window.navigator.userAgent.indexOf("OPR") > -1 || window.navigator.userAgent.indexOf("Opera") > -1) && this.supportedWebkit()
};