#!/usr/bin/env ruby
require 'yaml'
require 'fileutils'

# ===============================
# Konfiguration
# ===============================

# Pfad zur global_indicators.yml Datei
YAML_FILE = './translations/de/global_indicators.yml'

# Zielverzeichnis für die .csv Dateien
DATA_DIR = 'data'

# ===============================
# Funktionen
# ===============================

# Funktion zum Erstellen der CSV-Inhalte
def generate_csv_content
  <<~CSV
    Year,Value
    2019,1
    2020,2
  CSV
end

# ===============================
# Hauptprogramm
# ===============================

# Überprüfen, ob die YAML-Datei existiert
unless File.exist?(YAML_FILE)
  puts "Fehler: Die Datei #{YAML_FILE} wurde nicht gefunden."
  exit 1
end

# Laden der YAML-Datei
begin
  indicators = YAML.load_file(YAML_FILE)
rescue Psych::SyntaxError => e
  puts "Fehler beim Parsen der YAML-Datei: #{e.message}"
  exit 1
end

# Erstellen des Zielverzeichnisses, falls es nicht existiert
FileUtils.mkdir_p(DATA_DIR)

# Iterieren über jede Indikatornummer und Maßnahme
indicators.each do |key, measure|
  # Erwartetes Format des Schlüssels: "1-1-title"
  if key =~ /^(\d+)-(\d+)-title$/
    main = Regexp.last_match(1)
    sub = Regexp.last_match(2)

    # Dateiname: "indicator_1-1.csv"
    filename = "indicator_#{main}-#{sub}.csv"
    filepath = File.join(DATA_DIR, filename)

    # Erstellen des Inhalts
    content = generate_csv_content

    # Schreiben der .csv Datei
    begin
      File.write(filepath, content)
      puts "Erstellt: #{filepath}"
    rescue StandardError => e
      puts "Fehler beim Schreiben der Datei #{filepath}: #{e.message}"
    end
  else
    puts "Warnung: Schlüssel '#{key}' entspricht nicht dem erwarteten Format 'x-y-title' und wurde übersprungen."
  end
end

puts "Alle .csv Dateien wurden erfolgreich erstellt im Ordner '#{DATA_DIR}'."
