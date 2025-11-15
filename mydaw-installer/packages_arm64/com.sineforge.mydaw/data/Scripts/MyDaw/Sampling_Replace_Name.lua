function m(s)
  reaper.ShowConsoleMsg(tostring(s) .. "\n")
end






function getUserInput()
    -- Prompt user for input
    local ok, user_input = reaper.GetUserInputs("Replace String", 2, "Find Text,Replace With", "")
    
    if user_input == "" then
        return nil, nil -- User canceled the input
    elseif user_input then
        local find_text, replace_with = user_input:match("([^,]+),([^,]+)")
        return find_text, replace_with
    else
        return nil, nil
    end
end


function escape(text)
    text=text:gsub('%-', '%%-')
    text=text:gsub('%+', '%%+')
    text=text:gsub('%.', '%%.')
    text=text:gsub('%(', '%%(')
    text=text:gsub('%)', '%%)')
    text=text:gsub('%*', '%%*')
    text=text:gsub('%?', '%%?')
    text=text:gsub('%[', '%%[')
    text=text:gsub('%]', '%%]')
    return text
end





function replaceString(item, find_text, replace_with)
    -- Get the current item name
    local item_name = reaper.GetTakeName(reaper.GetActiveTake(item))
    
    
    find_text = escape(find_text)
    replace_with = escape(replace_with)
     
    
    -- Replace the part of the string
    local new_item_name= item_name:gsub(find_text, replace_with)
    
   -- m(new_item_name)
    
    -- Set the new name for the item
    reaper.GetSetMediaItemTakeInfo_String(reaper.GetActiveTake(item), "P_NAME", new_item_name, true)
end

function main()
    reaper.Undo_BeginBlock()

    local find_text, replace_with = getUserInput()
    
    
   
    

    if find_text and replace_with then
        local num_selected_items = reaper.CountSelectedMediaItems(0)
        
        if num_selected_items > 0 then
            for i = 0, num_selected_items - 1 do
                local item = reaper.GetSelectedMediaItem(0, i)
                replaceString(item, find_text, replace_with)
            end
            reaper.UpdateArrange()
        else
            reaper.ShowMessageBox("No selected items found.", "Error", 0)
        end
    end

    reaper.Undo_EndBlock("Replace String in Item Names", -1)
end

main()
