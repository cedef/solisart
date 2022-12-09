#!/usr/bin/env ruby


require 'httparty'
require 'base64'

require 'pp'

SOLISART_INSTALLATION_ID=ENV["SOLISART_INSTALLATION_ID"]
SOLISART_HOST=ENV["SOLISART_HOST"]
SOLISART_USER=ENV["SOLISART_USER"]
SOLISART_PASSWD=ENV["SOLISART_PASSWD"]


TEMP_MIN_BALLON_TAMPON=28.0
TEMP_MAX_BALLON_TAMPON=65.0

SOLISART_DATA = {
  "157" => "T_maison_confort",
  #"158" => "donnee_TConfort_1",
  #"159" => "donnee_TConfort_2",
  #"160" => "donnee_TConfort_3",
  #"161" => "donnee_TConfort_4",
  #"162" => "donnee_TConfort_5",
  "163" => "T_eau_chaude_confort",
  "164" => "T_maison_reduit",
  #"166" => "donnee_TReduit_2",
  #"167" => "donnee_TReduit_3",
  #"168" => "donnee_TReduit_4",
  #"169" => "donnee_TReduit_5",
  "170" => "T_eau_chaude_reduit",
  "584" => "T1_Capteur_???",
  "585" => "T2_Capteur_froi  d",
  "586" => "T3_Bal_solaire",
  "587" => "T4_Bal_appoint_sanitaire",
  "588" => "T5_Bal_Tampon",
  "589" => "T6_Chaudière",
  "590" => "T7_Collecteur_froid",
  "591" => "T8_Collecteur_chaud",
  "592" => "T9_Exterieur",
  "594" => "T11_Maison",
  "627" => "V3V_0",
  "628" => "V3V_1",
  "631" => "Consigne_T_Maison",
  "644" => "T_Capteur_solaire",
  "651" => "C4_Bal_Appoint",
  "652" => "C5_Bal_Solaire",
  "653" => "C6_Bal_Tampon",
  "654" => "C7_Appoint_2",
  "672" => "Temps_restant_derogation_zone1",
  "678" => "Temps_restant_derogation",
  # Added by cedef
  "9588" => "PCT_Bal_Tampon",
}





def retrieve_data
    #resp = HTTParty.get('http://192.168.1.42/')
    #puts "Cookies: #{session_cookie}"
    
    resp_login = HTTParty.post("#{SOLISART_HOST}/admin/?page=installation&id=#{SOLISART_INSTALLATION_ID}",
                               :body => { :id => SOLISART_USER,
                                          :pass => SOLISART_PASSWD,
                                          :ihm => "admin",
                                          :connexion => "Se+connecter" },
                                          )
    
    cookie_hash = HTTParty::CookieHash.new
    session_cookie = resp_login.get_fields("Set-Cookie").each { |c| cookie_hash.add_cookies(c) }
    #puts resp_login.code
    #puts resp_login.headers["set-cookie"]
    #puts resp_login.body.slice(0..300)
    
    resp_data = HTTParty.post("#{SOLISART_HOST}/admin/divers/ajax/lecture_valeurs_donnees.php",
                              :body => { :id      => Base64.encode64(SOLISART_INSTALLATION_ID),
                                         :heure   => "0",
                                         :periode => 5 },
                              :headers => { :Cookie => cookie_hash.to_cookie_string } )
    return resp_data.body.split("\n").last.gsub(/valeur /, "").gsub(/ \//, "").split("><").reject{|l| l.start_with? "<valeurs " or l.start_with? "/valeurs>"}
end

def calculate_pct_ballon_tampon(temperature_ballon_tampon)
  return Integer((Float(temperature_ballon_tampon) - TEMP_MIN_BALLON_TAMPON) * (100.0/(TEMP_MAX_BALLON_TAMPON - TEMP_MIN_BALLON_TAMPON)));
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
    else
      unit = ""
    end
    value.gsub!(/\s+dC/, "")
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

def raw_output(records)
  records.each do |k, record|
    puts "#{record[:label]} #{record[:value]}"
  end
end

def get_value_by_label(records, label)
  h = records.select{|k,v| v[:label] == label}
  return h.values.first[:value]
end

def table_view(records)
  puts """
    T° Consigne:           #{get_value_by_label(records, "Consigne_T_Maison")}°C
    T11° Maison:           #{get_value_by_label(records, "T11_Maison")}°C
    T9° Extérieure:        #{get_value_by_label(records, "T9_Exterieur")}°C

    T5° Ballon Tampon:     #{get_value_by_label(records, "T5_Bal_Tampon")}°C   (#{get_value_by_label(records, "PCT_Bal_Tampon")}%)
    T4° Ballon sanitaire:  #{get_value_by_label(records, "T4_Bal_appoint_sanitaire")}°C

    T6° Chaudière:         #{get_value_by_label(records, "T6_Chaudière")}°C

    T° Capteurs solaires:  #{get_value_by_label(records, "T_Capteur_solaire")}°C
    T1° Capteurs T1:       #{get_value_by_label(records, "T1_Capteur_???")}°C
  """
end

xml_array = retrieve_data
#xml_array = File.open('lecture-donnees-brutes-output.xml').readlines.last.gsub(/valeur /, "").gsub(/ \//, "").split("><").reject{|l| l.start_with? "<valeurs " or l.start_with? "/valeurs>"}

result = {}
xml_array.each do |l|
  h = decode_xml_line l
  result[h[:donnee]] = h
  if h[:donnee] == "588"
    result["9588"] = h.clone
    result["9588"][:label] = SOLISART_DATA["9588"]
    result["9588"][:value] = calculate_pct_ballon_tampon( h[:value] )
    result["9588"][:unit] = "%"
  end
end

#table_output result.select{ |k,v| v[:label] != "UNDEF"}
table_view result.select{ |k,v| v[:label] != "UNDEF"}
