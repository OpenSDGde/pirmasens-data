#!/usr/bin/env ruby
require 'roo'
require 'yaml'

# Pfad zur Excel-Datei
EXCEL_FILE = 'Path/to/Indikatoren_.xlsx'

# Pfad zur Ausgabe-YAML-Datei
YAML_FILE = 'global_indicators.yml'

# Spaltenbuchstaben für Indikatornummer und Maßnahme
INDICATOR_COLUMN_LETTER = 'E'
MEASURE_COLUMN_LETTER = 'B'

# Funktion zum Umwandeln eines Spaltenbuchstabens in eine Spaltennummer
def column_letter_to_number(letter)
  number = 0
  letter.upcase.each_char do |char|
    number = number * 26 + (char.ord - 'A'.ord + 1)
  end
  number
end

# Überprüfen, ob die Excel-Datei existiert
unless File.exist?(EXCEL_FILE)
  puts "Fehler: Die Datei #{EXCEL_FILE} wurde nicht gefunden."
  exit 1
end

# Hash zur Speicherung der Zuordnungen
global_indicators = {}

begin
  # Excel-Datei einlesen
  xlsx = Roo::Spreadsheet.open(EXCEL_FILE)

  # Wähle das erste Blatt (oder passe es bei Bedarf an)
  sheet = xlsx.sheet(0)

  # Umwandlung der Spaltenbuchstaben in Spaltennummern
  indicator_col = column_letter_to_number(INDICATOR_COLUMN_LETTER)
  measure_col = column_letter_to_number(MEASURE_COLUMN_LETTER)

  # Überprüfen, ob die Spaltennummern gültig sind
  max_col = sheet.last_column
  if indicator_col > max_col || measure_col > max_col
    puts "Fehler: Eine der angegebenen Spalten (#{INDICATOR_COLUMN_LETTER}, #{MEASURE_COLUMN_LETTER}) existiert nicht in der Excel-Datei."
    exit 1
  end

  # Iteriere über die Zeilen, beginnend ab der zweiten Zeile (angenommen, die erste Zeile ist der Header)
  (2..sheet.last_row).each do |row_num|
    indicator = sheet.cell(row_num, indicator_col)&.to_s&.strip
    measure = sheet.cell(row_num, measure_col)&.to_s&.strip

    # Überprüfen, ob beide Felder vorhanden sind
    if indicator.nil? || indicator.empty? || measure.nil? || measure.empty?
      puts "Warnung: Eine Zeile mit fehlenden Daten wurde übersprungen (Zeile #{row_num})."
      next
    end

    # Entfernen von eventuellen trailing Punkten
    clean_indicator = indicator.gsub(/\.$/, '')

    # Splitten der Indikatornummer in Haupt- und Unterindikator
    parts = clean_indicator.split('.')
    if parts.length != 2 || !parts.all? { |part| part.match?(/^\d+$/) }
      puts "Warnung: Ungültiges Indikatorformat '#{indicator}' (Zeile #{row_num})."
      next
    end

    main, sub = parts
    key = "#{main}-#{sub}-title"

    if global_indicators.key?(key)
      puts "Warnung: Duplikat für Schlüssel '#{key}' gefunden. Überschreibt den vorherigen Eintrag (Zeile #{row_num})."
    end

    global_indicators[key] = measure
  end

  # Speichern des Hashes als YAML
  File.open(YAML_FILE, 'w', encoding: 'UTF-8') do |file|
    file.write(global_indicators.to_yaml)
  end

  puts "global_indicators.yml wurde erfolgreich erstellt."

rescue Roo::FileNotFound => e
  puts "Fehler: Datei nicht gefunden - #{e.message}"
  exit 1
rescue Roo::UnsupportedSpreadsheet => e
  puts "Fehler: Dateityp wird nicht unterstützt - #{e.message}"
  exit 1
rescue NoMethodError => e
  puts "Fehler: #{e.message}"
  exit 1
rescue StandardError => e
  puts "Ein unerwarteter Fehler ist aufgetreten: #{e.message}"
  exit 1
end
