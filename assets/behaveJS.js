// Copyright (c) 2009 RightScale, Inc.
// 
// Permission is hereby granted, free of charge, to any person obtaining
// a copy of this software and associated documentation files (the
// 'Software'), to deal in the Software without restriction, including
// without limitation the rights to use, copy, modify, merge, publish,
// distribute, sublicense, and/or sell copies of the Software, and to
// permit persons to whom the Software is furnished to do so, subject to
// the following conditions:
// 
// The above copyright notice and this permission notice shall be
// included in all copies or substantial portions of the Software.
// 
// THE SOFTWARE IS PROVIDED 'AS IS', WITHOUT WARRANTY OF ANY KIND,
// EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
// MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
// IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
// CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
// TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
// SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
// 
// Author : Eugene Gimelberg

(function()
{
	var behaviorSelector	 				= "[data-behaves*=':']",
			clickBehaviorSelector			= "[data-behaves*='click:']",
			clickBehaviorExtract  		= /click:(\w+)/,
			behaviorAttr							= "data-behaves",
			delegatedAttr							= "data-delegated",
			delegatedAttrSelector			= "[data-delegated=click]",
			readyDestructorCacheKey  	= "behaveJSReadyDestructor",
			coreBehaviorsKey					= "behaveJSCoreBehaviors";
	
	function _getStorageKey(controller, action)
	{
		var name = controller;
		if (action) name += ("_" + action);
		
		return name.toLowerCase();
	}
	
	function _inititalizeActiveBehaviors()
	{
		// add the core behaviors, which are not based on controllers/actions		
		Object.extend(activeBehaviors, allBehaviors[coreBehaviorsKey]);
			
		// add behaviors defined for the current controller and for both the current controller and current action
		// behaviors defined with more specificity will take precedence
		var controllerBehaviors       = allBehaviors[behaveJS.settings.controllerName];
		var controllerActionBehaviors = allBehaviors[_getStorageKey(behaveJS.settings.controllerName, behaveJS.settings.actionName)];

		[ controllerBehaviors, controllerActionBehaviors].each(function(b) { if (b) Object.extend(activeBehaviors, b); });
	}
	// internal helper functions for attaching/detaching behaviors
	
	function _getBehaviorList(elem)
	{
		var list = elem.readAttribute(behaviorAttr).split(/;|:/);

		if (list.length % 2 != 0) list.pop();

		return list;
	}
	
	function _iterateDescendentsWithBehaviors(rootElem, callback)
	{
		// find all descendent elements contain a behavior attribute
		var collection = rootElem.select(behaviorSelector);
	 	
		// the root element may need to be observed as well
   	if (rootElem.match(behaviorSelector)) collection.push(rootElem);

	 	for (var iter = 0, length = collection.length; iter < length; ++iter)
		{
			callback(collection[iter]);
		}
	}
	
	function _bindBehaviorsToElement(behaviors, elem)
	{
		var behaviorList = _getBehaviorList(elem), 
				eventName    = null, 
				behaviorName = null, 
				behavior     = null;

		for (var iter = 0, length = behaviorList.length; iter < length; iter+=2)
		{
			eventName    = behaviorList[iter];
			behaviorName = behaviorList[iter + 1];
			
			// we skip the click event as we are using event delegation for that
			if (eventName == "click") continue;

			behavior = behaviors[behaviorName];
			
			if (behavior)
			{
				if (eventName != "ready")
        {
					elem.observe(eventName, behavior);
				}
        else
				{
					// for the ready event, we just call the behavior with a custom "dataavailable" event
					var event = elem.fire("behaveJS:ready"), data = behavior.call(elem, event);
					
					// ready event behaviors often return a destructor function, so we store it in Element Storage
					// and call it when detaching behaviors later on
          if (data) elem.store(readyDestructorCacheKey, data);
        }
      }
		}
	}

	function _delegateBehaviors(elem, behaviors)
  {
  	if (!(elem = $(elem))) return;
		
		// we only delegate click events
   	var eventName = "click";

   	// define event handler to be called when the root element has the provided event occur
   	var delegatedEventHandler = function(event)
   	{
    	// find the nearest element with a click behavior
    	var observedElement = event.findElement(clickBehaviorSelector);

			// ignore the event if no element was found
     	if (!observedElement) return;

			// get the behavior associated with the "click" event from the element's data-behaves attribute
			var behaviorName = clickBehaviorExtract.exec(observedElement.readAttribute(behaviorAttr))[1];
			
			// set the context of the behavior to be the nearest element with a click behavior
     	if (behaviors[behaviorName]) behaviors[behaviorName].call(observedElement, event);
    };

   	elem.observe(eventName, delegatedEventHandler);
   	elem.writeAttribute(delegatedAttr, eventName);
  }

	function _removeBehaviorsFromElement(elem)
	{
		var behaviorList = _getBehaviorList(elem), eventName = null;

		for(var iter = 0, length = behaviorList.length; iter < length; iter+=2)
		{
			eventName = behaviorList[iter];
			
			// we skip the click event as we are using event delegation for that and nothing else needs to be done, maybe needed????
			if (eventName == "click") continue;

    	if (eventName != "ready")
			{
				elem.stopObserving(eventName);
			}
			else
			{
				var data = elem.retrieve(readyDestructorCacheKey);
				
				if (data)
				{
					data();
					elem.store(readyDestructorCacheKey, null);
        }
      }
		}
  }
	
	// the default behavior for handling confirmations, popups, and non HTTP GET requests on links
	function _defaultBehavior(event)
	{
		if (!behaveJS.Helpers.confirmation.call(this, event)) return;

		// confirmation succeeded or was not required, check if popup configuration is set
		var popupCallback = behaveJS.Helpers.popup.call(this, event);

		if (popupCallback)
		{
			popupCallback();
			return;
		}

		// no popup was opened, see if link needs to do a non http GET request
		behaveJS.Helpers.method.call(this, event);
	}
	
	function _remoteBehavior(event)
	{
		event.stop();
		
		if (!behaveJS.Helpers.confirmation.call(this, event)) return;
		behaveJS.Helpers.remote.call(this);
	}
	
	// helper implementations used by the default behavior, can be overridden by user in behaveJS.Helpers module
	function _confirmationHelper(event)
	{
		var content = this.readConfigAttribute("confirm", null);

		// no confirmation message to display
		if (!content) return true;

		if (confirm(content))
		{
			return true;
		}
		else
		{
			event.stop();
			return false;
		}
	}
	
	function _popupHelper(event)
	{
		var popup         = this.readConfigAttribute("popup"),
				windowName    = "", 
				windowOptions = "",
				href					= this.href;

		if (!popup) return null;
		
		popup = popup.evalJSON();

		windowName    = popup[0];
		windowOptions = popup[1] || "";
		
		// return callback that opens a new window with provided options
		return function() { event.stop(); window.open(href, windowName, windowOptions) };		
	}
	
	function _methodHelper(event)
	{
		var method	= this.readConfigAttribute("method", "get");

		// nothing to do for a plain get request
		if (/get/i.test(method)) return;

		// method is other than get, need to create form and submit it
		event.stop();

		var form = new Element("form", { "style" : "display:none;", "method" : "post", "action" : this.href });

		if (!/post/i.test(method))
		{
			// need to create a hidden input _method
			form.insert(new Element("input", { "type" : "hidden", "name" : "_method", "value" : method }));
		}

		$(document.body).insert(form);
		form.submit();	
	}
	
	// helpers used for performing remote requests and calling RemoteActions
	function _remoteHelper(options)
	{
		// the context of this method is the element (A or FORM) or string to use as the basis of the remote request
		var obj = this, option;

		// default options for request
		var requestOptions = 
		{
	 		onComplete : function(response)
	   	{
				behaveJS.Helpers.onRemoteComplete.call(obj, response);
	    }
		};
		
		options = Object.clone(options || {});
		
		// set the context of any callbacks to be the object that is used to perform the remote request
		for (option in options)
		{
			if (Object.isFunction(options[option])) options[option] = options[option].bind(obj);
		}
		
		// allow user supplied options to override our default options
	  Object.extend(requestOptions, options);

		if (Object.isElement(obj))
		{
			// we have defined #request method for "A" elements as well
		 	return obj.request(requestOptions);	
		}
		else
		{
			return (new Ajax.Request(obj, requestOptions));
		}
	}
	
	function _onRemoteCompleteHelper(response)
	{
		// the context of this method is the element (A or FORM) or string to use as the basis of the remote request
		var remoteAction = null;
		
		if 	(Object.isElement(this)) remoteAction = this.readConfigAttribute("remoteAction");

	  var responseData = response.responseJSON;

		// a remoteAction attribute was not present in the element, look to see what server responded with	
		if (!remoteAction) remoteAction = responseData && responseData.remoteAction;

		if (!remoteAction || remoteAction.blank()) return;

		// request failed so the "failure handler" should be called
	  if (!response.request.success()) remoteAction += "Failure";

	  try
	  {
			var handler = remoteActions[remoteAction];

			// call the remote action handler in the context of the element that triggered the remote request
	    if (handler) handler.call(this, response);
	  }
	  catch (error)
	  {
			behaveJS.onError(error);
	  }
	}
		
	var	controllers 		= {},	// storage for all controllers
			remoteActions		= {}, // storage for all remote actions
			allBehaviors 		= {},	// storage for all behaviors, active and inactive
			// storage for all behaviors that are active for the current controller and action
	 		activeBehaviors = { "default" : _defaultBehavior, "remote" : _remoteBehavior };
		
	allBehaviors[coreBehaviorsKey] = {};

	var behaveJS = 
	{
		version 	 : 1.0,
		settings   : { },
		controller : null,
		Helpers 	 :	
		{
			confirmation 			: _confirmationHelper,
			popup 			 			: _popupHelper,
			method 			 			: _methodHelper,
			remote			 			: _remoteHelper,
			onRemoteComplete 	: _onRemoteCompleteHelper
		},
		onError	: function(error)
		{
			// default error displays the error in the console if its available
			if (window.console) window.console.error(error);
		},
		bootstrap : function(settings)
		{
			if (!settings.controllerName || !settings.actionName) 
			{
				this.onError(new SyntaxError("behaveJS: controller name or action name are missing"));
				return;
			}
			
			settings.controllerName = settings.controllerName.toLowerCase();
			settings.actionName     = settings.actionName.toLowerCase();
			this.settings       		= settings;
			
			document.observe("dom:loaded", this.onDomLoaded.bind(this));
		},
		onDomLoaded : function()
		{
			try
			{
				// find a controller to instantiate, but default to the application controller if one is not defined
				var controllerClass = controllers[this.settings.controllerName] || controllers["application"];

				// compute the active behaviors to be used for the current controller and action
				_inititalizeActiveBehaviors();

				// create controller object
				this.controller = new controllerClass();

				// call the action method of the controller if it has been defined
				if (this.controller[this.settings.actionName]) this.controller[this.settings.actionName]();
			
				// finally attach behaviors to the body of the document. this must be done as the last step as some 
				// behaviors may have dependencies on objects created in the controller
				behaveJS.attachBehaviors($(document.body));
			}
			catch (error)
			{
				this.onError(error);
			}
		},
		addBehaviors : function()
		{
			// ========================================================================================================================
			// Adds behaviors for a specific controller/action or to the universal collection applicable to all pages
			// Examples:
		  // 
			//  behaveJS.addBehaviors( { show_dialog : function(event) { ... } });
			// 		- Adds the "show_dialog" behavior to every page no matter of the controller or action
		  // 
			//  behaveJS.addBehaviors( { controller : "items" }, { show_dialog : function(event) { ... } });
			// 		- Adds the "show_dialog" behavior to all pages that have use controller "items"
		  // 
			//  behaveJS.addBehaviors( { controller : "items", actions : "new" }, { show_dialog : function(event) { ... } });
			// 		- Adds the "show_dialog" behavior to only the page using the controller "items" and the action "new"
			// ========================================================================================================================
			if (arguments.length == 0) return;
			
			var behaviorKey = coreBehaviorsKey, newBehaviors = arguments[0];

			if (arguments.length == 2)
			{
				// behaviors are being added to a specific controller/action
				newBehaviors = arguments[1];
				behaviorKey  = _getStorageKey(arguments[0].controller, arguments[0].action)
			}
			
			allBehaviors[behaviorKey] = Object.extend(allBehaviors[behaviorKey] || {}, newBehaviors);
		},
		createController : function(controllerName, methods)
		{
			controllerName = controllerName.toLowerCase();
			
			if (controllerName == "application")
			{
				// create the application controller
				controllers[controllerName] = Class.create(methods);
			}
			else
			{
				// create subclass of the application controller
				controllers[controllerName] = Class.create(controllers["application"], methods);
			}
		},
		attachBehaviors : function(element, optBehaviors)
		{
			var behaviors 					 = (optBehaviors || activeBehaviors),
					bindBehaviorCallback = _bindBehaviorsToElement.curry(behaviors);

    	if (!(element = $(element))) return;
				
			if (optBehaviors || !element.up(delegatedAttrSelector))
			{
				// we setup event delegation on the element if is not within another element
				// that has event delegation enabled or if we are attaching custom behaviors other
				// then the active ones.
				_delegateBehaviors(element, behaviors);
			}
				
			// bind behaviors to individual elements we are not using event delegation on
			_iterateDescendentsWithBehaviors(element, bindBehaviorCallback);
		},
		detachBehaviors : function (elem)
		{
			if (!(elem = $(elem))) return;

			// the element is being used for click delegation, so stop observing it
			if (elem.readAttribute(delegatedAttr) == "click")
			{
	    	elem.stopObserving("click");
	     	elem.writeAttribute(delegatedAttr, "");
	   	}
			
			// remove behaviors from individual elements that we were not using event delegation for
			_iterateDescendentsWithBehaviors(elem, _removeBehaviorsFromElement);
		},
		addRemoteActions : function(actions)
		{
			Object.extend(remoteActions, actions);
		}
	};
	
	window.behaveJS = behaveJS;
})();

// convenience functions to read and write HTML5 compatible configuration attributes from an element
// "data-" is automatically prefixed to the beginning of the attribute name. readConfigAttribute supports default values
Element.addMethods(
{
	readConfigAttribute : function(element, attr, defaultValue)
	{
		if (!(element = $(element))) return null;
		
		var value = element.readAttribute("data-" + attr);
		
		if (value)
		{
			if (value == "true") 				return true;
			else if (value == "false") 	return false;
	 		else 												return value;
		}
		else
		{
			if (Object.isUndefined(defaultValue)) defaultValue = null;
			return defaultValue;
		}
	},
	writeConfigAttribute : function(element, attr, value)
	{
		if (!(element = $(element))) return null;

		element.writeAttribute("data-" + attr, (value ? value.toString() : ""));
		return element;
	}
});

// adds a #request function to all link elements - modeled after the Form#request function
Element.addMethods("A", 
{
	request : function(element, options)
	{
		element = $(element), options = Object.clone(options || { });

		var params = options.parameters, href = element.readAttribute('href') || '';
    if (href.blank()) return null;

    options.parameters = { };

    if (params) 
		{
			if (Object.isString(params)) params = params.toQueryParams();
		  Object.extend(options.parameters, params);
		}

		var method = element.readConfigAttribute("method");
		if (method && !options.method)
		{
			options.method = method;
		}
		
		options.method = options.method || "GET";

   	return new Ajax.Request(href, options);	
	}
});

// Add Element.Storage if it doesn't already exist (Added in Prototype 1.6.1)
if (!Element.Storage)
{
	Element.Storage = {
	  UID: 1
	};

	Element.addMethods({
	  getStorage: function(element) {
	    if (!(element = $(element))) return;

	    var uid;
	    if (element === window) {
	      uid = 0;
	    } else {
	      if (typeof element._prototypeUID === "undefined")
	        element._prototypeUID = [Element.Storage.UID++];
	      uid = element._prototypeUID[0];
	    }

	    if (!Element.Storage[uid])
	      Element.Storage[uid] = $H();

	    return Element.Storage[uid];
	  },

	  store: function(element, key, value) {
	    if (!(element = $(element))) return;

	    if (arguments.length === 2) {
	      Element.getStorage(element).update(key);
	    } else {
	      Element.getStorage(element).set(key, value);
	    }

	    return element;
	  },

	  retrieve: function(element, key, defaultValue) {
	    if (!(element = $(element))) return;
	    var hash = Element.getStorage(element), value = hash.get(key);

	    if (Object.isUndefined(value)) {
	      hash.set(key, defaultValue);
	      value = defaultValue;
	    }

	    return value;
	  },

	  clone: function(element, deep) {
	    if (!(element = $(element))) return;
	    var clone = element.cloneNode(deep);
	    clone._prototypeUID = void 0;
	    if (deep) {
	      var descendants = Element.select(clone, '*'),
	          i = descendants.length;
	      while (i--) {
	        descendants[i]._prototypeUID = void 0;
	      }
	    }
	    return Element.extend(clone);
	  }
	});
}
