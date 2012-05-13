﻿import gfx.io.GameDelegate;
import Shared.GlobalFunc;
import gfx.ui.NavigationCode;

import skyui.util.ConfigManager;


class ItemMenu extends MovieClip
{
  /* CONSTANTS */
  
	private var SKSE_REQ_RELEASE_IDX = 9;


  /* PRIVATE VARIABLES */
  
	private var _platform: Number;
	private var _bItemCardFadedIn: Boolean;
	
	private var _3DIconXSettingStr: String;
	private var _3DIconZSettingStr: String;
	private var _3DIconScaleSettingStr: String;
	private var _3DIconWideXSettingStr: String;
	private var _3DIconWideZSettingStr: String;
	private var _3DIconWideScaleSettingStr: String;
	
	private var _config: Object;
	
	private var _bFadedIn: Boolean;
	
	
  /* STAGE ELEMENTS */
	
	public var inventoryLists: InventoryLists;
	
	var ItemCardFadeHolder_mc: MovieClip;
	var ItemCard_mc:MovieClip;
	var BottomBar_mc:MovieClip;
	
	var MouseRotationRect: MovieClip;
	var ExitMenuRect: MovieClip;
	var skseWarning: MovieClip;


	function onLoad()
	{
		trace("INIT extensions");
		InitExtensions();
		trace("INIT extensions done");
		
		GetInventoryItemList();
	}

	function ItemMenu()
	{
		super();
		
//		inventoryLists = inventoryLists;
		ItemCard_mc = ItemCardFadeHolder_mc.ItemCard_mc;
//		BottomBar_mc = BottomBar_mc;
		
		Mouse.addListener(this);
		ConfigManager.registerLoadCallback(this, "onConfigLoad");
		
		_bFadedIn = true;
		_bItemCardFadedIn = false;
		
		_3DIconXSettingStr = "fInventory3DItemPosX:Interface";
		_3DIconZSettingStr = "fInventory3DItemPosZ:Interface";
		_3DIconScaleSettingStr = "fInventory3DItemPosScale:Interface";
		_3DIconWideXSettingStr = "fInventory3DItemPosXWide:Interface";
		_3DIconWideZSettingStr = "fInventory3DItemPosZWide:Interface";
		_3DIconWideScaleSettingStr = "fInventory3DItemPosScaleWide:Interface";
	}

	// @API
	function InitExtensions(a_bPlayBladeSound)
	{
		skse.ExtendData(true);
		skse.ForceContainerCategorization(true);
		skse.Log("asdf " + inventoryLists);
		
		
		GameDelegate.addCallBack("UpdatePlayerInfo",this,"UpdatePlayerInfo");
		GameDelegate.addCallBack("UpdateItemCardInfo",this,"UpdateItemCardInfo");
		GameDelegate.addCallBack("ToggleMenuFade",this,"ToggleMenuFade");
		GameDelegate.addCallBack("RestoreIndices",this,"RestoreIndices");
		
		inventoryLists.addEventListener("categoryChange",this,"onCategoryChange");
		inventoryLists.addEventListener("itemHighlightChange",this,"onItemHighlightChange");
		inventoryLists.addEventListener("showItemsList",this,"onShowItemsList");
		inventoryLists.addEventListener("hideItemsList",this,"onHideItemsList");
		inventoryLists.itemList.addEventListener("itemPress",this,"onItemSelect");
		ItemCard_mc.addEventListener("quantitySelect",this,"onQuantityMenuSelect");
		ItemCard_mc.addEventListener("subMenuAction",this,"onItemCardSubMenuAction");

		positionElements();
		
		inventoryLists.showCategoriesList(a_bPlayBladeSound);
		
		ItemCard_mc._visible = false;
		BottomBar_mc.HideButtons();
		
		ExitMenuRect.onMouseDown = function()
		{
			if (_parent._bFadedIn == true && Mouse.getTopMostEntity() == this)
				_parent.onExitMenuRectClick();
		};
		
		if (skseWarning != undefined) {
			
			// Default message
			if (_global.skse == undefined) {
				skseWarning._visible = true;
				skseWarning.message.text = "SkyUI could not detect the Skyrim Script Extender (SKSE).\n"
					+ "SkyUI will not work correctly!\n"
					+ "\n"
					+ "This message may also appear if a new Skyrim Patch has been released.\n"
					+ "In this case, wait until SKSE has been updated, then install the new version.\n"
					+ "\n"
					+ "For more information, see the mod description.";
					
			} else if (_global.skse.version.releaseIdx < SKSE_REQ_RELEASE_IDX) {
				skseWarning._visible = true;
				skseWarning.message.text = "Your Skyrim Script Extender (SKSE) is outdated.\n"
					+ "SkyUI will not work correctly!\n"
					+ "\n"
					+ "Installed version: " + _global.skse.version.major + "." + _global.skse.version.minor + "." + _global.skse.version.beta + "\n"
					+ "Required version: 1.4.8\n"
					+ "\n"
					+ "For more information, see the mod description.";
					
			} else {
				skseWarning._visible = false;
			}
		}
	}
	
	public function onConfigLoad(event): Void
	{
		_config = event.config;
	}

	private function positionElements(): Void
	{
		GlobalFunc.SetLockFunction();
		
		inventoryLists.Lock("L");
		inventoryLists._x = inventoryLists._x - 20;
		
		var leftEdge = Stage.visibleRect.x + Stage.safeRect.x;
		var rightEdge = Stage.visibleRect.x + Stage.visibleRect.width - Stage.safeRect.x;
		
		var a = inventoryLists.getContentBounds();
		// 25 is hardcoded cause thats the final offset after the animation of the panel container is done
		var panelEdge = inventoryLists._x + a[0] + a[2] + 25;
		
		BottomBar_mc.PositionElements(leftEdge, rightEdge);

		var itemCardContainer = ItemCard_mc._parent;
		var itemcardPosition = _config.ItemInfo.itemcard;
		var itemiconPosition = _config.ItemInfo.itemicon;
		
		var scaleMult = (rightEdge - panelEdge) / itemCardContainer._width;
		
		// Scale down if necessary
		if (scaleMult < 1.0) {
			itemCardContainer._width *= scaleMult;
			itemCardContainer._height *= scaleMult;
			itemiconPosition.scale *= scaleMult;
		}
		
		if (itemcardPosition.align == "left")
			itemCardContainer._x = panelEdge + leftEdge + itemcardPosition.xOffset;
		else if (itemcardPosition.align == "right")
			itemCardContainer._x = rightEdge - itemCardContainer._width + itemcardPosition.xOffset;
		else
			itemCardContainer._x = panelEdge + itemcardPosition.xOffset + (Stage.visibleRect.x + Stage.visibleRect.width - panelEdge - itemCardContainer._width) / 2;

		itemCardContainer._y = itemCardContainer._y + itemcardPosition.yOffset;
		
		MovieClip(ExitMenuRect).Lock("TL");
		ExitMenuRect._x = ExitMenuRect._x - Stage.safeRect.x;
		ExitMenuRect._y = ExitMenuRect._y - Stage.safeRect.y;
		
		
		var iconX = GlobalFunc.Lerp(0, 128, Stage.visibleRect.x, (Stage.visibleRect.x + Stage.visibleRect.width), (itemCardContainer._x + (itemCardContainer._width / 2)));
		iconX = -(iconX - 64);
		
		skse.SetINISetting(_3DIconWideScaleSettingStr, (itemiconPosition.scale));
		skse.SetINISetting(_3DIconWideXSettingStr, (iconX + itemiconPosition.xOffset));
		skse.SetINISetting(_3DIconWideZSettingStr, (12 + itemiconPosition.yOffset));
		skse.SetINISetting(_3DIconScaleSettingStr, (itemiconPosition.scale));
		skse.SetINISetting(_3DIconXSettingStr, (iconX + itemiconPosition.xOffset));
		skse.SetINISetting(_3DIconZSettingStr, (16 + itemiconPosition.yOffset));

		if (MouseRotationRect != undefined) {
			MovieClip(MouseRotationRect).Lock("T");
			MouseRotationRect._x = ItemCard_mc._parent._x;
			MouseRotationRect._width = ItemCard_mc._parent._width;
			MouseRotationRect._height = 0.55 * Stage.visibleRect.height;
		}
		
		if (skseWarning != undefined)
			skseWarning.Lock("TR");
	}

	function SetPlatform(a_platform, a_bPS3Switch)
	{
		_platform = a_platform;
		inventoryLists.setPlatform(a_platform,a_bPS3Switch);
		ItemCard_mc.SetPlatform(a_platform,a_bPS3Switch);
		BottomBar_mc.SetPlatform(a_platform,a_bPS3Switch);
	}

	// API
	function GetInventoryItemList()
	{
		skse.Log("CALLED ME SOON DEAD SAD " + inventoryLists);
		skse.Log("CALLED ME SOON DEAD SAD " + inventoryLists.itemList);
		trace("CALLED ME SOON DEAD SAD " + inventoryLists);
		trace("CALLED ME SOON DEAD SAD " + inventoryLists.itemList);
		return inventoryLists.itemList;
	}

	// GFx
	function handleInput(details, pathToFocus)
	{
		if (_bFadedIn)
			if (!pathToFocus[0].handleInput(details, pathToFocus.slice(1)))
				if (GlobalFunc.IsKeyPressed(details) && details.navEquivalent == NavigationCode.TAB)
					GameDelegate.call("CloseMenu",[]);

		return true;
	}

	function onMouseWheel(delta)
	{
		for (var e = Mouse.getTopMostEntity(); e != undefined; e = e._parent) {
			if (e == MouseRotationRect && ShouldProcessItemsListInput(false) || !_bFadedIn && delta == -1) {
				GameDelegate.call("ZoomItemModel",[delta]);
				continue;
			}
		}
	}

	function onExitMenuRectClick()
	{
		GameDelegate.call("CloseMenu",[]);
	}

	function onCategoryChange(event)
	{
	}
	
	function onItemHighlightChange(event)
	{
		super.onItemHighlightChange(event);
		
		if (event.index != -1) {
			if (!_bItemCardFadedIn) {
				_bItemCardFadedIn = true;
				ItemCard_mc.FadeInCard();
				BottomBar_mc.ShowButtons();
			}
			
			GameDelegate.call("UpdateItem3D",[true]);
			GameDelegate.call("RequestItemCardInfo",[],this,"UpdateItemCardInfo");
			
		} else {
			if (!_bFadedIn)
				resetMenu();
			
			if (_bItemCardFadedIn) {
				_bItemCardFadedIn = false;
				onHideItemsList();
			}
		}
	}
	
	/*
		This method is only used for the InventoryMenu Favorites Category.
		It prevents a lockup when unfavoriting the last item from favorites list by
		resetting the menu.
	*/
	function resetMenu()
	{
		SaveIndices();
		GameDelegate.call("CloseMenu",[]);
		skse.OpenMenu("Inventory Menu");
	}

	function onShowItemsList(event)
	{
		onItemHighlightChange(event);
	}

	function onHideItemsList(event)
	{
		GameDelegate.call("UpdateItem3D",[false]);
		ItemCard_mc.FadeOutCard();
		BottomBar_mc.HideButtons();
	}

	function onItemSelect(event)
	{
		if (event.entry.enabled) {
			if (event.entry.count > InventoryDefines.QUANTITY_MENU_COUNT_LIMIT)
				ItemCard_mc.ShowQuantityMenu(event.entry.count);
			else
				onQuantityMenuSelect({amount:1});
		} else {
			GameDelegate.call("DisabledItemSelect",[]);
		}
	}

	function onQuantityMenuSelect(event)
	{
		GameDelegate.call("ItemSelect",[event.amount]);
	}

	function UpdatePlayerInfo(aUpdateObj)
	{
		BottomBar_mc.UpdatePlayerInfo(aUpdateObj,ItemCard_mc.itemInfo);
	}

	function UpdateItemCardInfo(aUpdateObj)
	{
		ItemCard_mc.itemInfo = aUpdateObj;
		BottomBar_mc.UpdatePerItemInfo(aUpdateObj);
	}

	function onItemCardSubMenuAction(event)
	{
		if (event.opening == true) {
			inventoryLists.itemList.disableSelection = true;
			inventoryLists.itemList.disableInput = true;
			inventoryLists.categoryList.disableSelection = true;
			inventoryLists.categoryList.disableInput = true;
		} else if (event.opening == false) {
			inventoryLists.itemList.disableSelection = false;
			inventoryLists.itemList.disableInput = false;
			inventoryLists.categoryList.disableSelection = false;
			inventoryLists.categoryList.disableInput = false;
		}
	}

	function ShouldProcessItemsListInput(abCheckIfOverRect)
	{
		var process = _bFadedIn == true && inventoryLists.currentState == InventoryLists.SHOW_PANEL && inventoryLists.itemList.filteredItemsCount > 0 && !inventoryLists.itemList.disableSelection && !inventoryLists.itemList.disableInput;

		if (process && _platform == 0 && abCheckIfOverRect) {
			var e = Mouse.getTopMostEntity();
			var found = false;
			
			while (!found && e != undefined) {
				if (e == inventoryLists.itemList)
					found = true;
					
				e = e._parent;
			}
			
			process = process && found;
		}
		return process;
	}
	
	// Added to prevent clicks on the scrollbar from equipping/using stuff
	function ConfirmSelectedEntry():Boolean
	{
		// only confirm when using mouse
		if (_platform != 0)
			return true;
		
		for (var e = Mouse.getTopMostEntity(); e && e != undefined; e = e._parent)
			if (e.itemIndex == inventoryLists.itemList.selectedIndex)
				return true;
				
		return false;
	}

	function onMouseRotationStart()
	{
		GameDelegate.call("StartMouseRotation",[]);
		inventoryLists.categoryList.disableSelection = true;
		inventoryLists.itemList.disableSelection = true;
	}

	function onMouseRotationStop()
	{
		GameDelegate.call("StopMouseRotation",[]);
		inventoryLists.categoryList.disableSelection = false;
		inventoryLists.itemList.disableSelection = false;
	}

	function onMouseRotationFastClick()
	{
		if (ShouldProcessItemsListInput(false))
			onItemSelect({entry:inventoryLists.itemList.selectedEntry, keyboardOrMouse:0});
	}

	function ToggleMenuFade()
	{
		if (_bFadedIn) {
			_parent.gotoAndPlay("fadeOut");
			_bFadedIn = false;
			inventoryLists.itemList.disableSelection = true;
			inventoryLists.itemList.disableInput = true;
			inventoryLists.categoryList.disableSelection = true;
			inventoryLists.categoryList.disableInput = true;
		} else {
			_parent.gotoAndPlay("fadeIn");
		}
	}

	// API
	function SetFadedIn()
	{
		_bFadedIn = true;
		inventoryLists.itemList.disableSelection = false;
		inventoryLists.itemList.disableInput = false;
		inventoryLists.categoryList.disableSelection = false;
		inventoryLists.categoryList.disableInput = false;
	}
	
	function RestoreIndices()
	{
		if (arguments[0] != undefined && arguments[0] != -1 && arguments.length == 3) {
			inventoryLists.categoryList.restoreCategory(arguments[0]);
			inventoryLists.itemList.scrollPosition = arguments[2];
			inventoryLists.itemList.selectedIndex = arguments[1];
		} else {
			inventoryLists.categoryList.restoreCategory(1); // ALL
		}
		
		inventoryLists.categoryList.UpdateList();
	}

	function SaveIndices()
	{
		var a = new Array();
		
		// Save selected category, selected item and relative scroll position
		a.push(inventoryLists.categoryList.selectedIndex);
		a.push(inventoryLists.itemList.selectedIndex);
		a.push(inventoryLists.itemList.scrollPosition);
		
		GameDelegate.call("SaveIndices", [a]);
	}
}