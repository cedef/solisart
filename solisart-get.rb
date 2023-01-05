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
  :flamme => "🔥",
  :maison => "🏠",
  :meteo_ext => "⛅",
  :soleil => "🌞",
  :thermometre => "🌡",
  :fleche_boucle => "🔃",
}

CACHE_FOLDER = "/tmp/solisart"
Dir.mkdir(CACHE_FOLDER) unless Dir.exist? CACHE_FOLDER


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
  "163" => "consigne_t_eau_chaude_confort",
  "164" => "t_maison_reduit",
  #"166" => "donnee_treduit_2",
  #"167" => "donnee_treduit_3",
  #"168" => "donnee_treduit_4",
  #"169" => "donnee_treduit_5",
  "170" => "consigne_t_eau_chaude_reduit",
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
  "c4_ballon_sanitaire_haut",
  "c5_ballon_sanitaire_bas",
  "c6_ballon_tampon",
  "c7_appoint_2",
  "c1_maison",
  "c2_unknown",
]

NATIVE_SOLISART_CSV_FIELDS = {
  "Date"          =>  "",
  "Tcapt"         =>  "t1_capteur_solaire",
  "TcaptF"        =>  "t2_chaudiere_capteur_froid",
  "TbalS"         =>  "t3_ballon_sanitaire_bas",
  "TbalA"         =>  "t4_ballon_sanitaire_haut",
  "TalT"          =>  "t5_ballon_tampon",
  "TpoeleB"       =>  "t6_chaudiere",
  "TretC"         =>  "t15_retour_capteur",
  "TdepC"         =>  "t10_chaud_echangeur",
  "Text"          =>  "t9_exterieur",
  "Tcap2"         =>  "",
  "TZ1"           =>  "t11_maison",
  "TZ2"           =>  "",
  "TZ3"           =>  "",
  "TZ4"           =>  "",
  "T15"           =>  "t15_retour_capteur",
  "T16"           =>  "t16",
  "Deb1"          =>  "",
  "Deb2"          =>  "",
  "Deb3"          =>  "",
  "Deb4"          =>  "",
  "Deb5"          =>  "",
  "HC/HP"         =>  "",
  "APP"           =>  "APP",
  "SOL"           =>  "SOL",
  "BTC"           =>  "BTC",
  "C7"            =>  "c7_appoint_2",
  "C1"            =>  "c1_maison",
  "C2"            =>  "c2_unknown",
  "C3"            =>  "c3_unknown",
  "V3VAB"         =>  "v3vab",
  "V3VAS"         =>  "v3vas",
  "S10"           =>  "s10",
  "S11"           =>  "s11",
  "V3VSS"         =>  "v3vss",
  "V3VSB"         =>  "v3vsb",
  "chdr1"         =>  "chdr1",
  "chdr2"         =>  "chdr2",
  "Tcons1"        =>  "consigne_t_maison",
  "Tcons2"        =>  "",
  "Tcons3"        =>  "",
  "Tcons4"        =>  "",
  "TconsECS"      =>  "",
  "POSV3VSOL"     =>  "posv3vsol",
  "POSV3VAPP"     =>  "posv3vapp",
  "POSV3VOPT"     =>  "posv3vopt",
  "DemZ1"         =>  "DemZ1",
  "DemZ2"         =>  "",
  "DemZ3"         =>  "",
  "DemZ4"         =>  "",
  "DemECS"        =>  "DemECS",
  "MD"            =>  "MD",
  "dtcapt3mn"     =>  "",
  "TconPisc_dep"  =>  "",
  "Tcaptcalc"     =>  "Tcaptcalc",
  "anticc_chd"    =>  "anticc_chd",
  "var_cir"       =>  "",
  "demPisc_D"     =>  "",
  "def_T"         =>  "",
  "def"           =>  "",
  "tfmoy"         =>  "",
  "index1"        =>  "",
  "index2"        =>  "",
  "index3"        =>  "",
  "index4"        =>  "",
  "index5"        =>  "",
  "index6"        =>  "",
  "index1S"       =>  "",
  "index2S"       =>  "",
  "index3S"       =>  "",
  "index4S"       =>  "",
  "index5S"       =>  "",
  "index6S"       =>  "",
}

def datename_to_strftime(datename)
  if datename == "month"
    return DateTime.now.strftime("%Y-%m")
  elsif datename == "lastmonth"
    lastmonth = DateTime.now.prev_month
    return lastmonth.strftime("%Y-%m")
  else
    return DateTime.strptime(datename).strftime("%Y-%m")
  end
end

def retrieve_data(from)
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

    if from == "webui"
      resp_data = HTTParty.post("#{$solisart_host}/admin/divers/ajax/lecture_valeurs_donnees.php",
                                :body => { :id      => Base64.encode64($solisart_installation_id),
                                           :heure   => "0",
                                           :periode => 5 },
                                :headers => { :Cookie => cookie_hash.to_cookie_string } )
      return resp_data.body.split("\n").last.gsub(/valeur /, "").gsub(/ \//, "").split("><").reject{|l| l.start_with? "<valeurs " or l.start_with? "/valeurs>"}
    else
      if from == "month"
        date_ym = datename_to_strftime(from)
        resp_data = HTTParty.get("#{$solisart_host}/admin/export.php?fichier=donnees-#{$solisart_installation_id}-#{date_ym}.csv",
          :body => {
            :id      => Base64.encode64($solisart_installation_id),
          },
          :headers => { :Cookie => cookie_hash.to_cookie_string } )
        retcsv = CSV.parse(resp_data.gsub(/SolisConfrt VsD\.03\+6\n/, ""), headers = true, col_sep = ";")
        pp retcsv
      end
      # 1 retrieve file
      # 2 if from == month => file is csv, return CSV array
      # 3 if from != mobth => file is zip, unzip then return CSV array
    end
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

def get_table_output(records)
  cible_chaleur = {
    :haut_ballon => "    ",
    :bas_ballon  => "    ",
    :maison => "    ",
    :ballon_tampon => "    ",
  }
  if get_value_by_label(records, "pct_v3v_solaire") != "100"
    production_chaleur = EMOJIS[:soleil]
  elsif get_value_by_label(records, "c6_ballon_tampon") == "100"
    production_chaleur = EMOJIS[:batterie]
  else
    production_chaleur = EMOJIS[:flamme]
  end
  if get_value_by_label(records, "circulateur_ballon_sanitaire_haut") != "0"
    cible_chaleur[:haut_ballon] = "#{production_chaleur}  "
  end
  if get_value_by_label(records, "circulateur_ballon_sanitaire_bas") != "0"
    cible_chaleur[:bas_ballon] = "#{production_chaleur}  "
  end
  if get_value_by_label(records, "circulateur_maison") != "0"
    cible_chaleur[:maison] = "#{production_chaleur}  "
  end
  if get_value_by_label(records, "circulateur_ballon_sanitaire_haut") == "0" and \
      get_value_by_label(records, "circulateur_ballon_sanitaire_bas") == "0" and \
      get_value_by_label(records, "circulateur_maison") == "0"
    cible_chaleur[:ballon_tampon] = "#{production_chaleur}  "
  end

  return """
    T°   Consigne:                  #{EMOJIS[:thermometre]}   #{get_value_by_label(records, "consigne_t_maison")}°C
#{cible_chaleur[:maison]}T11° Maison:                    #{EMOJIS[:maison]}  #{get_value_by_label(records, "t11_maison")}°C

    T9° Extérieure:                 #{EMOJIS[:meteo_ext]}  #{get_value_by_label(records, "t9_exterieur")}°C

    T1° Capteurs solaire:           #{EMOJIS[:soleil]}  #{get_value_by_label(records, "t1_capteur_solaire")}°C

        -> retour capteur:          #{EMOJIS[:fleche_boucle]}  #{get_value_by_label(records, "t15_retour_capteur")}°C
        -> chaud échangeur:         #{EMOJIS[:eau_chaude]}  #{get_value_by_label(records, "t10_chaud_echangeur")}°C

    T6° Chaudière:                  #{EMOJIS[:bois]}   #{get_value_by_label(records, "t6_chaudiere")}°C

#{cible_chaleur[:ballon_tampon]}T5° Ballon Tampon:              #{EMOJIS[:batterie]}  #{get_value_by_label(records, "t5_ballon_tampon")}°C   (#{get_value_by_label(records, "pct_bal_tampon")}%)

    T°  Consigne sanitaire:         #{EMOJIS[:thermometre]}   #{get_value_by_label(records, "consigne_t_eau_chaude_confort")}°C
#{cible_chaleur[:haut_ballon]}T4° Ballon sanitaire (haut):    #{EMOJIS[:eau_chaude]}  #{get_value_by_label(records, "t4_ballon_sanitaire_haut")}°C
#{cible_chaleur[:bas_ballon]}T3° Ballon sanitaire (bas):     #{EMOJIS[:eau_froide]}  #{get_value_by_label(records, "t3_ballon_sanitaire_bas")}°C


    circ_sanitaire (haut): #{get_value_by_label(records, "circulateur_ballon_sanitaire_haut")}%
    circ_sanitaire (bas):  #{get_value_by_label(records, "circulateur_ballon_sanitaire_bas")}%
    circ_maison:           #{get_value_by_label(records, "circulateur_maison")}%
    pct_v3v_solaire: :     #{get_value_by_label(records, "pct_v3v_solaire")}%
    pct_v3v_chaudiere:     #{get_value_by_label(records, "pct_v3v_chaudiere")}%

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
  ["--input",           "-i", GetoptLong::OPTIONAL_ARGUMENT],
)

# DEFAULT VARIABLES:
$format = "fancy"
$output_filename = nil
$output_append = false
$csv_headers = true
$get_data_from = "webui"

$solisart_installation_id=ENV["SOLISART_INSTALLATION_ID"] if ENV.has_key? "SOLISART_INSTALLATION_ID"
$solisart_host=ENV["SOLISART_HOST"] if ENV.has_key? "SOLISART_HOST"
$solisart_user=ENV["SOLISART_USER"] if ENV.has_key? "SOLISART_USER"
$solisart_passwd=ENV["SOLISART_PASSWD"] if ENV.has_key? "SOLISART_PASSWD"
$cache_folder=ENV["SOLISART_CACHE_FOLDER"] if ENV.has_key? "SOLISART_CACHE_FOLDER"

opts.each do |opt, arg|
  case opt
    when '--help'
      puts "#{$0} [options]

    -h, --help           : show this help message
    -f, --format <format>: output format. Valid formats: csv, json or fancy
                           (default: fancy)
    -O, --output         : write output to file
    -C, --output         : cache folder where to write downloaded CSV/ZIP files

    -I, --installation-id <id>
    -u, --user <username>
    -p, --passwd <passwd>
    -s, --host <host-ip>
    -i, --input webui,month,lastmonth,<yyyy-mm> (defaults to webui)
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
    when '--input'
      if arg == ''
        $get_data_from = "month"
      else
        $get_data_from = arg
      end
  end
end

data = retrieve_data($get_data_from)
if $get_data_from == "webui"
  xml_array = data
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
elsif $get_data_from == "month"
  csv = data
else
  zipfile = data
end
