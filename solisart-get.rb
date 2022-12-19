#!/usr/bin/env ruby


require 'getoptlong'
require 'httparty'
require 'base64'
require 'date'

require 'pp'

EMOJIS = {
  :bois => "🪵",
  :batterie => "🔋",
  :eau_chaude => "🩸",
  :eau_froide => "💧",
  :flame => "🔥",
  :maison => "🏠",
  :meteo_ext => "🌤",
  :soleil => "🌞",
  :thermometre => "🌡",
}


TEMP_MIN_BALLON_TAMPON=28.0
TEMP_MAX_BALLON_TAMPON=65.0

SOLISART_DATA = {
  #"150" => "mode_chauffage_maison",
  "157" => "t_maison_confort",
  #"158" => "donnee_tconfort_1",
  #"159" => "donnee_tconfort_2",
  #"160" => "donnee_tconfort_3",
  #"161" => "donnee_tconfort_4",
  #"162" => "donnee_tconfort_5",
  "163" => "t_eau_chaude_confort",
  "164" => "t_maison_reduit",
  #"166" => "donnee_treduit_2",
  #"167" => "donnee_treduit_3",
  #"168" => "donnee_treduit_4",
  #"169" => "donnee_treduit_5",
  "170" => "t_eau_chaude_reduit",
  "584" => "t1_capteur_solaire",
  "585" => "t2_chaudiere_capteur_froid",
  "586" => "t3_ballon_sanitaire_bas",
  "587" => "t4_ballon_sanitaire_haut",
  "588" => "t5_ballon_tampon",
  "589" => "t6_chaudiere",
  "590" => "t7_chaudiere_collecteur_froid",
  "591" => "t8_chaudiere_collecteur_chaud",
  "592" => "t9_exterieur",
  "593" => "t10_chaud_echangeur",
  "594" => "t11_maison",
  "598" => "t15_retour_capteur",
  "614" => "circulateur_ballon_sanitaire_haut",
  "615" => "circulateur_ballon_sanitaire_bas",
  "616" => "circulateur_ballon_tampon",
  "617" => "circulateur_chaudiere",
  "618" => "circulateur_maison",
  "624" => "circulateur_solaire",
  "627" => "pct_v3v_solaire",
  "628" => "pct_v3v_chaudiere",
  "631" => "consigne_t_maison",
  # redondant avec 584/t1 capteur solaire
  #"644" => "t_capteur_solaire",
  "651" => "c4_ballon_sanitaire_haut",
  "652" => "c5_ballon_sanitaire_bas",
  "653" => "c6_ballon_tampon",
  "654" => "c7_appoint_2",
  "655" => "c1_maison",
  "656" => "c2_unknown",
  "672" => "temps_restant_derogation_zone1",
  "678" => "temps_restant_derogation",
  # added by cedef
  "9588" => "pct_bal_tampon",
}

CSV_FIELDS = [
  "time",
  "consigne_t_maison",
  "t1_capteur_solaire",
  "t3_ballon_sanitaire_bas",
  "t4_ballon_sanitaire_haut",
  "t5_ballon_tampon",
  "t6_chaudiere",
  "t9_exterieur",
  "t10_chaud_echangeur",
  "t11_maison",
  "t15_retour_capteur",
  "circulateur_ballon_sanitaire_haut",
  "circulateur_ballon_sanitaire_bas",
  "circulateur_ballon_tampon",
  "circulateur_chaudiere",
  "circulateur_maison",
  "circulateur_solaire",
  "pct_v3v_solaire",
  "pct_v3v_chaudiere",
]

def retrieve_data
    #resp = HTTParty.get('http://192.168.1.42/')
    #puts "Cookies: #{session_cookie}"
    
    resp_login = HTTParty.post("#{$solisart_host}/admin/?page=installation&id=#{$solisart_installation_id}",
                               :body => { :id => $solisart_user,
                                          :pass => $solisart_passwd,
                                          :ihm => "admin",
                                          :connexion => "Se+connecter" },
                                          )
    
    cookie_hash = HTTParty::CookieHash.new
    session_cookie = resp_login.get_fields("Set-Cookie").each { |c| cookie_hash.add_cookies(c) }
    #puts resp_login.code
    #puts resp_login.headers["set-cookie"]
    #puts resp_login.body.slice(0..300)
    
    resp_data = HTTParty.post("#{$solisart_host}/admin/divers/ajax/lecture_valeurs_donnees.php",
                              :body => { :id      => Base64.encode64($solisart_installation_id),
                                         :heure   => "0",
                                         :periode => 5 },
                              :headers => { :Cookie => cookie_hash.to_cookie_string } )
    return resp_data.body.split("\n").last.gsub(/valeur /, "").gsub(/ \//, "").split("><").reject{|l| l.start_with? "<valeurs " or l.start_with? "/valeurs>"}
end

def calculate_pct_ballon_tampon(temperature_ballon_tampon)
  raw_pct =  Integer((Float(temperature_ballon_tampon) - TEMP_MIN_BALLON_TAMPON) * (100.0/(TEMP_MAX_BALLON_TAMPON - TEMP_MIN_BALLON_TAMPON)));
  # ensure   0 < %
  ret_pct = [0, raw_pct].max
  return ret_pct
end

def decode_xml_line(line)
  begin
    match = /heure=\"(?<heure>\d+)\" donnee=\"(?<donnee>[a-zA-Z0-9=]+)\" valeur=\"(?<valeur>[a-zA-Z0-9=]*)\"/.match line
    timestamp = Integer(match["heure"])
    if SOLISART_DATA.has_key? match["donnee"]
      label = SOLISART_DATA[match["donnee"]]
    else
      label = "UNDEF"
    end
    value = Base64.decode64(match["valeur"])
    if value.include? "dC"
      unit = "°C"
    elsif value.include? "pC"
      unit = "%"
    else
      unit = ""
    end
    value.gsub!(/\s+dC/, "")
    value.gsub!(/pC$/, "")
    return { :timestamp => timestamp,
             :date => Time.at(timestamp).to_datetime.strftime("%F %T"),
             :donnee => match["donnee"],
             :label => label,
             :value => value,
             :unit => unit,
    }
  rescue => detail
    STDERR.puts "Unable to decode: #{line}"
  end
end

def process_data xml_array
  results = {}
  xml_array.each do |l|
    h = decode_xml_line l
    results[h[:donnee]] = h
    if h[:donnee] == "588"
      results["9588"] = h.clone
      results["9588"][:label] = SOLISART_DATA["9588"]
      results["9588"][:value] = calculate_pct_ballon_tampon( h[:value] )
      results["9588"][:unit] = "%"
      results["9588"][:donnee] = "9588"
    end
  end
  # Remove all records with UNDEF label
  return results.select{ |k,v| v[:label] != "UNDEF"}
end

def get_raw_output(records)
  retstr = ""
  records.keys.sort.each do |k|
    record = records[k]
    retstr += "#{k} #{record[:label]} #{record[:value]}\n"
  end
  return retstr
end

def get_value_by_label(records, label)
  h = records.select{|k,v| v[:label] == label}
  begin
    if label == "time"
      return DateTime.now
    else
      return h.values.first[:value]
    end
  rescue => detail
    STDERR.puts "Invalid label: #{label}."
  end
end

def get_current_production(records)
  c4_haut_ballon = "haut de ballon sanitaire"
  c5_bas_ballon  = "bas de ballon sanitaire"
  c1_chauffage_maison = "maison"
  c6_ballon_tampon = "ballon tampon"

  if get_value_by_label(records, "c4_ballon_sanitaire_haut") == "1"
    c4_haut_ballon = "#{EMOJIS[:eau_chaude]} [" + c4_haut_ballon + "]" 
  end
  if get_value_by_label(records, "c5_ballon_sanitaire_bas") == "1"
    c4_haut_ballon = "#{EMOJIS[:eau_froide]} [" + c5_bas_ballon + "]" 
  end
  #if get_value_by_label(records, "") == "1"
  #  c4_haut_ballon = "#{$EMOJIS[:solaire]} [" + c4_haut_ballon + "]" 
  #end
  return c4_haut_ballon
end

def get_table_output(records)
  return """
    T°   Consigne:                  #{EMOJIS[:thermometre]}   #{get_value_by_label(records, "consigne_t_maison")}°C
    T11° Maison:                    #{EMOJIS[:maison]}  #{get_value_by_label(records, "t11_maison")}°C

    T9° Extérieure:                 #{EMOJIS[:meteo_ext]}   #{get_value_by_label(records, "t9_exterieur")}°C
    T1° Capteurs solaire:           #{EMOJIS[:soleil]}  #{get_value_by_label(records, "t1_capteur_solaire")}°C

    T6° Chaudière:                  #{EMOJIS[:bois]}   #{get_value_by_label(records, "t6_chaudiere")}°C

    T5° Ballon Tampon:              #{EMOJIS[:batterie]}  #{get_value_by_label(records, "t5_ballon_tampon")}°C   (#{get_value_by_label(records, "pct_bal_tampon")}%)
    T4° Ballon sanitaire (haut):    #{EMOJIS[:eau_chaude]}  #{get_value_by_label(records, "t4_ballon_sanitaire_haut")}°C
    T3° Ballon sanitaire (bas):     #{EMOJIS[:eau_froide]}  #{get_value_by_label(records, "t3_ballon_sanitaire_bas")}°C
  """
end

def get_csv_output(records)
  csv_array = []
  CSV_FIELDS.each do |f|
    csv_array << get_value_by_label(records, f)
  end
  csv_string = CSV.generate do |csv|
    if $csv_headers
      csv << CSV_FIELDS
    end
    csv << csv_array
  end
  return csv_string
end

def get_json_output(records)
  csv_array = []
  CSV_FIELDS.each do |f|
    csv_array << get_value_by_label(records, f)
  end
  csv_string = CSV.generate do |csv|
    if $csv_headers
      csv << CSV_FIELDS
    end
    csv << csv_array
  end
  return csv_string
end

opts = GetoptLong.new(
  ["--help",            "-h", GetoptLong::NO_ARGUMENT],
  ["--format",          "-f", GetoptLong::REQUIRED_ARGUMENT],
  ["--no-headers",      "-H", GetoptLong::NO_ARGUMENT],
  ["--output",          "-O", GetoptLong::REQUIRED_ARGUMENT],
  ["--append",          "-A", GetoptLong::NO_ARGUMENT],
  ["--user",            "-u", GetoptLong::REQUIRED_ARGUMENT],
  ["--passwd",          "-p", GetoptLong::REQUIRED_ARGUMENT],
  ["--host",            "-s", GetoptLong::REQUIRED_ARGUMENT],
  ["--installation-id", "-I", GetoptLong::REQUIRED_ARGUMENT],
)

# DEFAULT VARIABLES:
$format = "fancy"
$output_filename = nil
$output_append = false
$csv_headers = true

$solisart_installation_id=ENV["SOLISART_INSTALLATION_ID"] if ENV.has_key? "SOLISART_INSTALLATION_ID"
$solisart_host=ENV["SOLISART_HOST"] if ENV.has_key? "SOLISART_HOST"
$solisart_user=ENV["SOLISART_USER"] if ENV.has_key? "SOLISART_USER"
$solisart_passwd=ENV["SOLISART_PASSWD"] if ENV.has_key? "SOLISART_PASSWD"

opts.each do |opt, arg|
  case opt
    when '--help'
      puts "#{$0} [options]

    -h, --help           : show this help message
    -f, --format <format>: output format. Valid formats: csv, json or fancy
                           (default: fancy)
    -O, --output         : write output to file

    -I, --installation-id <id>
    -u, --user <username>
    -p, --passwd <passwd>
    -s, --host <host-ip>
"
      exit 2
    when '--format'
      $format = arg
    when '--no-headers'
      $csv_headers = false
    when '--output'
      $output_filename = arg
    when '--user'
      $solisart_user = arg
    when '--passwd'
      $solisart_passwd = arg
    when '--host'
      $solisart_host = arg
    when '--installation-id'
      $solisart_installation_id = arg
  end
end

xml_array = retrieve_data
results = process_data xml_array

if not $output_filename.nil? and File.exists? $output_filename and $format == "csv"
  $csv_headers = false
end

if $output_filename.nil?
  output = STDOUT
else
  output = File.open($output_filename, "a")
end

if $format == "fancy"
  o = get_table_output results
elsif $format == "csv"
  o = get_csv_output results
elsif $format == "raw"
  o = get_raw_output results
elsif $format == "json"
  o = get_json_output results
end
output.puts o
output.close
