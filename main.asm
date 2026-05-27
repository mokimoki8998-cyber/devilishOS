; 15:31 у нас в городе отрубили не только т2 интернтет, а еще вайфай
; 15:35 соси мой хуй роскомнадзор, я сам себе инет разблокал
; made by DeNeTeR



org 100h

section .text
start:
    cli
    mov ax, cs
    mov ss, ax
    mov sp, end_of_memory + 1024
    sti

    mov ds, ax
    mov es, ax

    mov ax, [002Ch]
    mov [exec_env], ax

auth_screen:
    call clear_screen
    
    mov ax, 0600h
    mov bh, 1Fh         
    mov cx, 0414h
    mov dx, 133Ch
    int 10h

    mov dh, 5
    mov dl, 28
    call set_cursor
    mov dx, msg_auth_title
    mov ah, 09h
    int 21h

    mov dh, 8
    mov dl, 24
    call set_cursor
    mov dx, msg_menu_1
    mov ah, 09h
    int 21h

    mov dh, 10
    mov dl, 24
    call set_cursor
    mov dx, msg_menu_2
    mov ah, 09h
    int 21h

    mov dh, 12
    mov dl, 24
    call set_cursor
    mov dx, msg_menu_3
    mov ah, 09h
    int 21h

    mov dh, 14
    mov dl, 24
    call set_cursor
    mov dx, msg_menu_4
    mov ah, 09h
    int 21h

    mov dh, 17
    mov dl, 24
    call set_cursor
    mov dx, msg_choice_prompt
    mov ah, 09h
    int 21h

.choice_loop:
    mov ah, 00h
    int 16h
    
    cmp al, '1'
    je near login_process
    cmp al, '2'
    je near register_process
    cmp al, '3'
    je near exit_prog
    cmp al, '4'
    je near factory_reset_process  
    jmp .choice_loop

factory_reset_process:

    mov ax, 0600h
    mov bh, 1Fh
    mov cx, 0816h
    mov dx, 1238h
    int 10h

    mov dh, 9
    mov dl, 24
    call set_cursor
    mov dx, msg_master_prompt
    mov ah, 09h
    int 21h

    mov dh, 11
    mov dl, 32
    call set_cursor
    call clear_auth_buffers
    mov di, input_pass
    call input_password_mask

    mov si, input_pass
    mov di, master_password
    mov cx, 8
    repe cmpsb
    jne .wrong_master

    mov ah, 41h
    mov dx, file_name
    int 21h

    mov dh, 13
    mov dl, 24
    call set_cursor
    mov dx, msg_reset_ok
    mov ah, 09h
    int 21h
    call wait_key
    jmp start

.wrong_master:
    mov dh, 13
    mov dl, 24
    call set_cursor
    mov dx, msg_auth_bad
    mov ah, 09h
    int 21h
    call wait_key
    jmp auth_screen

register_process:
    call clear_auth_buffers  
    call draw_input_fields

    mov dh, 10
    mov dl, 36
    call set_cursor
    mov di, input_user
    call input_string

    mov dh, 12
    mov dl, 36
    call set_cursor
    mov di, input_pass
    call input_password_mask

    mov ah, 3Ch         
    mov cx, 0           
    mov dx, file_name
    int 21h
    jc .error_reg
    mov [file_handle], ax
    mov bx, ax

    mov ah, 40h         
    mov cx, 32
    mov dx, input_user
    int 21h

    mov ah, 40h         
    mov cx, 32
    mov dx, input_pass
    int 21h

    mov ah, 3Eh
    mov bx, [file_handle]
    int 21h

    mov dh, 15
    mov dl, 24
    call set_cursor
    mov dx, msg_reg_ok
    mov ah, 09h
    int 21h
    call wait_key
    jmp auth_screen

.error_reg:
    mov dh, 15
    mov dl, 24
    call set_cursor
    mov dx, msg_err_file
    mov ah, 09h
    int 21h
    call wait_key
    jmp auth_screen

login_process:
    call clear_auth_buffers
    call draw_input_fields
    
    mov dh, 10
    mov dl, 36
    call set_cursor
    mov di, input_user
    call input_string

    mov dh, 12
    mov dl, 36
    call set_cursor
    mov di, input_pass
    call input_password_mask

    mov ah, 3Dh         
    mov al, 0           
    mov dx, file_name
    int 21h
    jc .auth_fail

    mov [file_handle], ax
    mov bx, ax

    mov ah, 3Fh
    mov cx, 32
    mov dx, stored_user
    int 21h

    mov ah, 3Fh
    mov cx, 32
    mov dx, stored_pass
    int 21h

    mov ah, 3Eh
    mov bx, [file_handle]
    int 21h

    mov si, input_user
    mov di, stored_user
    mov cx, 32
    repe cmpsb
    jne .auth_fail

    mov si, input_pass
    mov di, stored_pass
    mov cx, 32
    repe cmpsb
    jne .auth_fail

    jmp system_init_desktop

.auth_fail:
    mov dh, 15
    mov dl, 24
    call set_cursor
    mov dx, msg_auth_bad
    mov ah, 09h
    int 21h
    call wait_key
    jmp auth_screen

system_init_desktop:
    mov byte [app_count], 0

    mov ax, 0012h
    int 10h

    mov ah, 01h
    mov ch, 20h     
    int 10h

    call scan_applications

    mov ax, 0000h
    int 33h
    cmp ax, 0       
    je .no_mouse
    mov ax, 0001h   
    int 33h
.no_mouse:

    call draw_system_desktop

main_loop:
    cmp byte [console_open], 1
    je near console_input_loop


    mov ah, 01h     
    int 16h
    jz .check_mouse  

    mov ah, 00h     
    int 16h
    cmp al, 27      
    je near auth_screen  
.check_mouse:
    mov ax, 0003h   
    int 33h
    test bx, 1      
    jz main_loop    

    push cx
    push dx
    mov cx, 01h
    mov dx, 86A0h
    mov ah, 86h
    int 15h
    pop dx
    pop cx

    cmp byte [menu_open], 1
    je near menu_logic

    cmp dx, 450
    jb .check_desktop_icons
    cmp cx, 80
    ja main_loop
    jmp near open_menu

.check_desktop_icons:
    cmp byte [app_count], 0
    je main_loop
    cmp cx, 20
    jb main_loop
    cmp cx, 80
    ja main_loop

    xor si, si
.loop_click_apps:
    mov al, [app_count]
    cbw
    cmp si, ax
    jae main_loop    

    mov ax, si
    mov bl, 70
    mul bl
    add ax, 30      
    cmp dx, ax
    jb .next_icon_click
    add ax, 50      
    cmp dx, ax
    ja .next_icon_click

    mov ax, si
    mov bl, 13      
    mul bl          
    and ax, 00FFh   
    add ax, app_names
    mov si, ax      
    
    mov di, exec_filename
.copy_exec_name:
    lodsb
    stosb
    cmp al, 0
    jne .copy_exec_name

    jmp near execute_app 

.next_icon_click:
    inc si
    jmp .loop_click_apps

menu_logic:
    cmp cx, 120
    ja near close_menu
    cmp dx, 350
    jb near close_menu
    cmp dx, 380
    jbe near show_about
    cmp dx, 410
    jbe near open_console_window   
    cmp dx, 450
    jbe near auth_screen 

close_menu:
    call erase_menu
    jmp main_loop

execute_app:
    mov ax, 0002h       
    int 33h         

    mov ax, 0003h       
    int 10h         

    mov bx, end_of_memory + 1024  
    mov cl, 4
    shr bx, cl                    
    inc bx                        
    mov ah, 4Ah     
    int 21h

    mov word [exec_cmd_off], empty_tail
    mov word [exec_cmd_seg], cs
    mov word [exec_fcb1_off], 0FFFFh
    mov word [exec_fcb1_seg], cs
    mov word [exec_fcb2_off], 0FFFFh
    mov word [exec_fcb2_seg], cs


    mov dx, exec_filename    
    mov bx, exec_block       
    mov ax, 4B00h
    int 21h         


    jmp start


clear_auth_buffers:
    mov di, input_user
    xor al, al
    mov cx, 128         
    rep stosb
    ret

clear_screen:
    mov ax, 0600h
    mov bh, 07h
    xor cx, cx
    mov dx, 184Fh
    int 10h
    ret

set_cursor:
    mov ah, 02h
    mov bh, 0
    int 10h
    ret

wait_key:
    mov ah, 00h
    int 16h
    ret

draw_input_fields:
    mov ax, 0600h
    mov bh, 1Fh
    mov cx, 0916h
    mov dx, 1138h
    int 10h

    mov dh, 10
    mov dl, 24
    call set_cursor
    mov dx, msg_field_user
    mov ah, 09h
    int 21h

    mov dh, 12
    mov dl, 24
    call set_cursor
    mov dx, msg_field_pass
    mov ah, 09h
    int 21h
    ret

input_string:
    xor cx, cx
.loop:
    mov ah, 00h
    int 16h
    cmp al, 13          
    je .done
    cmp al, 8           
    je .backspace
    cmp cx, 30          
    jae .loop

    stosb
    inc cx
    mov ah, 0Eh
    int 10h
    jmp .loop
.backspace:
    jcxz .loop
    dec cx
    dec di
    mov ah, 0Eh
    mov al, 8
    int 10h
    mov al, ' '
    int 10h
    mov al, 8
    int 10h
    jmp .loop
.done:
    ret

input_password_mask:
    xor cx, cx
.loop:
    mov ah, 00h
    int 16h
    cmp al, 13          
    je .done
    cmp al, 8           
    je .backspace
    cmp cx, 30
    jae .loop

    stosb
    inc cx
    mov ah, 0Eh
    mov al, '*'         
    int 10h
    jmp .loop
.backspace:
    jcxz .loop
    dec cx
    dec di
    mov ah, 0Eh
    mov al, 8
    int 10h
    mov al, ' '
    int 10h
    mov al, 8
    int 10h
    jmp .loop
.done:
    ret

scan_applications:
    mov ah, 1Ah
    mov dx, disk_dta
    int 21h
    mov ah, 4Eh
    mov cx, 0007h      
    mov dx, search_mask
    int 21h
    jc .scan_done      
.save_app:
    mov si, disk_dta + 1Eh
    mov di, txt_win_check
    mov cx, 7
    repe cmpsb
    je .find_next
    mov bl, [app_count]
    xor bh, bh
    mov ax, 13
    mul bl
    add ax, app_names
    mov di, ax
    mov si, disk_dta + 1Eh 
.copy_name_char:
    lodsb
    stosb
    cmp al, 0
    jne .copy_name_char
    inc byte [app_count]
    cmp byte [app_count], 5 
    je .scan_done
.find_next:
    mov ah, 4Fh
    int 21h
    jnc .save_app
.scan_done:
    ret

console_input_loop:
    mov ax, 0003h   
    int 33h
    test bx, 1
    jnz near .check_close_click
    mov ah, 01h
    int 16h
    jz console_input_loop 
    mov ah, 00h
    int 16h               
    cmp al, 13            
    je near .process_command
    cmp al, 27            
    je near close_console_window
    cmp al, 8
    jne .not_backspace
    cmp byte [buffer_len], 0
    je console_input_loop
    dec byte [buffer_len]
    mov ah, 0Eh
    mov al, 8
    int 10h
    mov al, ' '
    int 10h
    mov al, 8
    int 10h
    jmp console_input_loop
.not_backspace:
    mov bl, [buffer_len]
    cmp bl, 63            
    jae console_input_loop
    xor bh, bh
    mov [input_buffer + bx], al
    inc byte [buffer_len]
    mov ah, 0Eh
    mov bl, 07h
    int 10h
    jmp console_input_loop
.check_close_click:
    cmp cx, 450
    jb console_input_loop
    cmp cx, 475
    ja console_input_loop
    cmp dx, 110
    jb console_input_loop
    cmp dx, 132
    ja console_input_loop
    jmp near close_console_window
.process_command:
    mov bl, [buffer_len]
    mov byte [input_buffer + bx], 0 
    mov ah, 02h
    mov bh, 0
    mov dh, [current_row]
    inc dh
    mov dl, 23
    int 10h
    cmp byte [input_buffer], '6'
    jne .check_dir
    cmp byte [input_buffer+1], '6'
    jne .check_dir
    cmp byte [input_buffer+2], '6'
    je near show_error 
.check_dir:
    cmp byte [input_buffer], 'd'
    jne .check_f_drive
    cmp byte [input_buffer+1], 'i'
    jne .check_f_drive
    cmp byte [input_buffer+2], 'r'
    jne .check_f_drive
    mov dx, msg_dir_res
    mov ah, 09h
    int 21h
    jmp near .reset_prompt
.check_f_drive:
    cmp byte [input_buffer], 'f'
    jne .check_cls
    mov dx, msg_f_res
    mov ah, 09h
    int 21h
    mov byte [txt_prompt], 'F'
    jmp near .reset_prompt
.check_cls:
    cmp byte [input_buffer], 'c'
    jne .check_help
    cmp byte [input_buffer+1], 'l'
    jne .check_help
    cmp byte [input_buffer+2], 's'
    jne .check_help
    call clear_internal_terminal
    jmp console_input_loop 
.check_help:
    cmp byte [input_buffer], 'h'
    jne .procedural_search
    mov dx, msg_help_res
    mov ah, 09h
    int 21h
    jmp near .reset_prompt

.procedural_search:
    cmp byte [buffer_len], 0
    je near .unknown_cmd
    mov si, input_buffer
    mov di, exec_filename
    xor cx, cx
    mov cl, [buffer_len]
.copy_loop:
    lodsb
    stosb
    loop .copy_loop
    cmp byte [buffer_len], 4
    jb .add_extension
    mov bx, exec_filename
    add bl, [buffer_len]
    sub bx, 4
    cmp byte [bx], '.'
    je .check_file_exists
.add_extension:
    mov byte [di], '.'
    mov byte [di+1], 'C'
    mov byte [di+2], 'O'
    mov byte [di+3], 'M'
    mov byte [di+4], 0
.check_file_exists:
    mov ah, 4Eh
    mov cx, 0
    mov dx, exec_filename
    int 21h
    jc near .unknown_cmd
    jmp near execute_app

.unknown_cmd:
    mov dx, msg_bad_cmd
    mov ah, 09h
    int 21h
.reset_prompt:
    add byte [current_row], 2
    cmp byte [current_row], 14
    jl .draw_next_prompt
    call clear_internal_terminal
.draw_next_prompt:
    mov ah, 02h
    mov bh, 0
    mov dh, [current_row]
    mov dl, 23
    int 10h
    mov dx, txt_prompt
    mov ah, 09h
    int 21h
    mov byte [buffer_len], 0 
    jmp console_input_loop

clear_internal_terminal:
    mov ax, 0002h
    int 33h
    mov ax, 0600h
    mov bh, 07h
    mov cx, 0916h
    mov dx, 1438h
    int 10h
    mov byte [current_row], 10
    mov ah, 02h
    mov bh, 0
    mov dh, 10
    mov dl, 23
    int 10h
    mov dx, txt_prompt
    mov ah, 09h
    int 21h
    mov byte [buffer_len], 0
    mov ax, 0001h
    int 33h
    ret

show_about:
    call erase_menu
    mov ax, 0002h
    int 33h         
    mov ah, 02h
    mov bh, 0
    mov dh, 1
    mov dl, 45
    int 10h
    mov dx, msg_about
    mov ah, 09h
    int 21h
    mov ax, 0001h
    int 33h         
    jmp main_loop

open_menu:
    mov byte [menu_open], 1
    mov ax, 0002h
    int 33h         
    mov ax, 0600h
    mov bh, 70h
    mov cx, 1600h
    mov dx, 1B0Eh
    int 10h
    mov ah, 02h
    mov bh, 0
    mov dh, 23
    mov dl, 2
    int 10h
    mov dx, pop_about
    mov ah, 09h
    int 21h
    mov ah, 02h
    mov bh, 0
    mov dh, 25
    mov dl, 2
    int 10h
    mov dx, pop_console
    mov ah, 09h
    int 21h
    mov ah, 02h
    mov bh, 0
    mov dh, 27
    mov dl, 2
    int 10h
    mov dx, pop_exit
    mov ah, 09h
    int 21h
    mov ax, 0001h
    int 33h         
    jmp main_loop

erase_menu:
    mov ax, 0002h
    int 33h         
    mov ax, 0600h
    mov bh, 33h
    mov cx, 1600h
    mov dx, 1B0Eh
    int 10h
    mov byte [menu_open], 0
    mov ax, 0001h
    int 33h         
    ret

open_console_window:
    call erase_menu
    mov byte [console_open], 1
    mov byte [buffer_len], 0 
    mov byte [current_row], 10 
    mov byte [txt_prompt], 'C' 
    mov ax, 0002h
    int 33h  
    mov ax, 0600h
    mov bh, 70h
    mov cx, 0714h
    mov dx, 113Ah
    int 10h
    mov ax, 0600h
    mov bh, 1Fh
    mov cx, 0714h
    mov dx, 073Ah
    int 10h
    mov ah, 02h
    mov bh, 0
    mov dh, 7
    mov dl, 21
    int 10h
    mov dx, txt_win_title
    mov ah, 09h
    int 21h
    mov ah, 02h
    mov bh, 0
    mov dh, 7
    mov dl, 56
    int 10h
    mov dx, btn_close
    mov ah, 09h
    int 21h
    mov ax, 0600h
    mov bh, 07h
    mov cx, 0916h
    mov dx, 1438h
    int 10h
    mov ah, 02h
    mov bh, 0
    mov dh, 10
    mov dl, 23
    int 10h
    mov dx, txt_prompt
    mov ah, 09h
    int 21h
    mov ax, 0001h
    int 33h  
    jmp main_loop

close_console_window:
    mov byte [console_open], 0
    mov ax, 0002h
    int 33h
    call draw_system_desktop
    mov ax, 0001h
    int 33h
    jmp main_loop

draw_system_desktop:
    mov ax, 0600h
    mov bh, 33h
    mov cx, 0000h
    mov dx, 1E4Fh
    int 10h
    mov ax, 0600h
    mov bh, 1Fh
    mov cx, 0000h
    mov dx, 014Fh
    int 10h
    mov ah, 02h
    mov bh, 0
    mov dh, 1
    mov dl, 20
    int 10h
    mov dx, txt_title
    mov ah, 09h
    int 21h
    mov ax, 0600h
    mov bh, 77h
    mov cx, 1C00h
    mov dx, 1D4Fh
    int 10h
    mov ah, 02h
    mov bh, 0
    mov dh, 28
    mov dl, 2
    int 10h
    mov dx, btn_start
    mov ah, 09h
    int 21h

    cmp byte [app_count], 0
    je .done_drawing_icons
    xor si, si
.draw_apps_loop:
    mov al, [app_count]
    cbw
    cmp si, ax
    jae .done_drawing_icons    
    mov ax, si
    mov bl, 7
    mul bl
    add ax, 2
    mov ch, al       
    add ax, 1
    mov dh, al       
    mov ax, 0600h
    mov bh, 77h      
    mov cl, 03h      
    mov dl, 05h      
    int 10h
    mov ax, si
    mov bl, 7
    mul bl
    add ax, 5
    mov ah, 02h
    mov bh, 0
    mov dh, al       
    mov dl, 2        
    int 10h
    mov ax, si
    mov bl, 13
    mul bl
    add ax, app_names
    mov bx, ax
.print_char_loop:
    mov al, [bx]
    cmp al, 0
    je .print_char_done
    cmp al, '.'
    je .print_char_done
    push bx
    mov ah, 0Eh
    mov bl, 07h
    int 10h
    pop bx
    inc bx
    jmp .print_char_loop
.print_char_done:
    inc si
    jmp .draw_apps_loop
.done_drawing_icons:
    ret

show_error:
    mov ax, 0002h
    int 33h
    mov ax, 0003h
    int 10h
    mov ax, 0600h
    mov bh, 1Fh
    mov cx, 0000h
    mov dx, 184Fh
    int 10h
    mov ah, 02h
    mov dh, 11
    mov dl, 14
    int 10h
    mov dx, msg_bsod_1
    mov ah, 09h
    int 21h
    mov ah, 02h
    mov dh, 13
    mov dl, 22
    int 10h
    mov dx, msg_bsod_2
    mov ah, 09h
    int 21h
.wait:
    mov ah, 00h
    int 16h
    cmp al, 27
    jne .wait
    jmp auth_screen 

exit_prog:
    mov ax, 0003h
    int 10h
    mov ax, 4C00h   
    int 21h

align 2
file_name       db 'USERS.DAT', 0
file_handle     dw 0

master_password db 'RES'

msg_auth_title  db '--- DEVILISH OS AUTHENTICATION ---$'
msg_menu_1      db '1. Login to system$'
msg_menu_2      db '2. Register new user$'
msg_menu_3      db '3. Shutdown PC$'
msg_menu_4      db '4. Factory Reset System$' 
msg_choice_prompt db 'Select option [1-4]: $'

msg_master_prompt db 'Enter Master Password: $'
msg_reset_ok      db 'System reset! All users wiped. Press key...$'

msg_field_user  db 'Username: $'
msg_field_pass  db 'Password: $'

msg_reg_ok      db 'Registration complete! Press key...$'
msg_auth_bad    db 'Invalid password!$'
msg_err_file    db 'Database file error!$'

menu_open    db 0
console_open db 0
buffer_len   db 0
current_row  db 10  

search_mask  db '*.COM', 0
txt_win_check db 'WIN.COM'
app_count    db 0

txt_title    db 'devilishOS v0.15 - Stable Custom Console$'
btn_start    db '[ START ]$'

pop_about    db '1. About   $'
pop_console  db '2. Console $'
pop_exit     db '3. Lock OS $' 
msg_about    db 'OS by DeNeTeR$'

txt_win_title db 'Devilish Console [Imitation Mode]$'
btn_close     db '[X]$'
txt_prompt    db 'C:\DEV_OS> $'

msg_bad_cmd   db 'Bad command or file not found!$'
msg_help_res  db 'Try: dir, cls, f:, 666$'
msg_dir_res   db 'WIN.COM  GAME.COM  LOCKS.COM$'
msg_f_res     db 'Switched to drive F:$'

msg_bsod_1   db 'A fatal exception 0E has occurred at 0028:C0011A65.$'
msg_bsod_2   db 'Press ESC to reboot devilishOS.$'

empty_tail   db 0, 13

align 2
exec_block:
exec_env       dw 0       
exec_cmd_off   dw 0
exec_cmd_seg   dw 0
exec_fcb1_off  dw 0
exec_fcb1_seg  dw 0
exec_fcb2_off  dw 0
exec_fcb2_seg  dw 0

input_user    times 32 db 0
input_pass    times 32 db 0
stored_user   times 32 db 0
stored_pass   times 32 db 0

input_buffer  times 64 db 0  
exec_filename times 64 db 0  
disk_dta      times 44 db 0  
app_names     times 80 db 0  

end_of_memory: