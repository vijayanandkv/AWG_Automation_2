import pyvisa
import time
import argparse
from logger import awg_logger

###################### Parse Arguments ####################################
'''def parse_args():
    parser = argparse.ArgumentParser(description="Instrument communication")
    parser.add_argument("--instrument", default= 'AWG_1', type=str,  
                        help="Instrument name (e.g., AWG, DSO, SignalGen)")
        
    parser.add_argument("--IP", type = str, default= "WINDOWS-EJL97HL",
                        help = "Indtrument IP address. default is WINDOWS-EJL97HL")
    return parser.parse_args()'''


class AWG_Controller:
    def __init__(self, instrument_name = 'AWG_1', ip_address = "WINDOWS-EJL97HL"): 

        #setup resource manager
        self.rm = pyvisa.ResourceManager()
        self.ip_address = ip_address
        self.instrument_name = instrument_name
        self._resource = None

        self.logger = awg_logger()
        if self.logger._log_file_path is None:
                self.logger._initialize_log_file(f"awg_{self.ip_address}")

        self.connect()

    ######################## Connection #########################################

    def connect(self):

        try:
            start_t = time.time()
            self._resource = self.rm.open_resource(f"TCPIP0::{self.ip_address}::inst0::INSTR")
            stop_t = time.time()
            response_t = (stop_t - start_t) * 1000
            status = self._resource.query("*IDN?")

            

            log = self.logger._log_command(command= f"TCPIP0::{self.ip_address}::inst0::INSTR", duration_ms= None, response= status)

            self.print_query_msg(response=status)
            return True

        except Exception as e:
            self.print_errors(f"Failed to make connection:\n reason: {e}")
            log = self.logger._log_command(command= f"TCPIP0::{self.ip_address}::inst0::INSTR", duration_ms= None, response= str(e))
            return False
        
    def is_connected(self):
        try:
            start_t = time.time()
            status = self._resource.query("*IDN?")
            stop_t = time.time()
            response_t = (stop_t - start_t) * 1000
            log = self.logger._log_command(command= f"TCPIP0::{self.ip_address}::inst0::INSTR", duration_ms= None, response= status)
            return True, log
        except Exception as e :
            log = self.logger._log_command(command= f"TCPIP0::{self.ip_address}::inst0::INSTR", duration_ms= None, response= str(e))
            return False, log

    
    def disconnect(self):
        try:
            start_t = time.time()
            self._resource.close()
            stop_t = time.time()

            response_t = (stop_t - start_t) * 1000
            log = self.logger._log_command(command= f"resource.close()", duration_ms= response_t, response= "Device disconnected!!")

            return log
        except Exception as e:
           log = self.logger._log_command(command= f"resourse.close()", duration_ms= None, response= str(e))
           self.print_errors(f"Filed to dissconnect:\n reason: {e}")
           return log

    ########################## Write and Query ##############################
            
    def query_instrument(self, query):
        try:
            response = self._resource.query(query)
        
            return response
        except Exception as e:
            self.print_errors(f"Error!!!!!! \n reason: {e}")
    
    def write_instrument(self, command):
        try:
            self._resource.write(command)

            return True
        except Exception as e:
            self.print_errors(f"Error!!!!! \n reason: {e}")
    
    ########################### Print Message and Errors #####################

    def print_msg(self, parameter_name:str, value:float, query_val:float, instrument_name = 'AWG_1'):
        instrument_name = instrument_name
        parameter_name = parameter_name
        value = value
        query_val = query_val

        if (value - query_val) != 0:
            print(f"{'#' * 60}\n")
            print(f"Message from {instrument_name}!!",
                 "{parameter_name} is set to {value}\n",
                 "The actual value is {query_val}\n",
                 "WARNING!!! set value is different from query value!!")
            print(f"{'#' * 60}\n")
        else:
            print(f"{'#' * 60}\n")
            print(f"Message from {instrument_name}!! \n",
                 "{parameter_name} is set to {value}\n",
                 "The actual value is {query_val}\n",
                 "SUCCESS!!! set value is equal to query value!!\n")
            print(f"{'#' * 60}\n")
    
    def print_query_msg(self, response: str):

        print(f"\n{'#' * 60}")
        print(f"{response}")
        print(f"{'#' * 60}\n")
            
    def print_errors(self, error_message: str):
        print(f"\n{'#' * 60}")
        print(f"❌ ERROR from {self.instrument_name}!!")
        print(f"{error_message}")
        print(f"{'#' * 60}\n")


    # CLEAR EVENT REGISTER ####
    def clear_event_reg(self):
        try:
            command = '*CLS'
            self.write_instrument(command=command)
            log = self.logger._log_command(command= f"*CLS", duration_ms= None, response= 'Event register cleared!!')
            print('Event register cleared!!')
            return log
        except Exception as e:
            self.print_errors(error_message=str(e))
            return log
    
    ########################### Voltage subsystem ############################
    
    #  QUERY VOLTAGE SUBSYSTEM

    # Query the ouput offset voltage of a channel
    def get_output_offset_voltage(self, channel:int):
        start_t = time.time()
        channel = str(channel)
        
        command = f":VOLT{channel}:OFFS?"
        stop_t = time.time()
        query = self.query_instrument(query=command)
        response_t = (stop_t - start_t) * 1000
        self.logger._log_command(command=f'{command}', duration_ms=response_t, response=self.query_instrument(":SYST:ERR?"))
        return float(query)
    
    #Query the output amplitude of a channel in volts
    def get_output_voltage(self, channel):
        try:
            start_t = time.time()
            channel = str(channel)

            command = f":VOLT{channel}?"
            query = self.query_instrument(query=command)
            stop_t = time.time()
            response_t = (stop_t - start_t) * 1000
            self.logger._log_command(command=command, duration_ms= response_t, response=query)
            self.print_query_msg(response=query)
            return float(query)
        except Exception as e:
            self.logger._log_command(command=command, duration_ms=response_t, response=self.query_instrument(":SYST:ERR?"))
            self.print_errors(error_message=str(e))
    
    #Query the Output glevl voltage
    def get_output_high_level(self, channel):
        channel = str(channel)
        try:
            command = f":VOLT{channel}:HIGH?"
            start_time = time.time()
            response = self.query_instrument(query=command)
            value = float(response.strip())
            duration = (time.time() - start_time) * 1000
            self.logger._log_command(command=command, duration_ms= duration, response=response)
            self.print_query_msg(response=response)
            return value
        except Exception as e:
            self.print_errors(error_message=str(e))
            self.logger._log_command(command=command, duration_ms= duration, response=self.query_instrument(":SYST:ERR?"))

    #Query output low level voltage
    def get_output_low_level(self, channel):
        channel = str(channel)
        try:
            command = f":VOLT{channel}:LOW?"
            start_time = time.time()
            response = self.query_instrument(query=command)
            value = float(response.strip())
            duration = (time.time() - start_time) * 1000
            self.logger._log_command(command=command, duration_ms= duration, response=response)
            self.print_query_msg(response=response)
            return value
        except Exception as e:
            self.logger._log_command(command=command, duration_ms= duration, response=self.query_instrument(":SYST:ERR?"))
            self.print_errors(error_message=str(e))

    #Query output termination voltage
    def get_output_termination(self, channel):
        channel = str(channel)
        try:
            command = f":VOLT{channel}:TERM?"
            start_time = time.time()
            response = self.query_instrument(query=command)
            value = float(response.strip())
            duration = (time.time() - start_time) * 1000
            self.logger._log_command(command=command, duration_ms= duration, response=response)
            self.print_query_msg(response=response)
            return value
        except Exception as e:
            self.logger._log_command(command=command, duration_ms= duration, response=self.query_instrument(":SYST:ERR?"))
            self.print_errors(error_message=str(e))
       
    # WRITE VOLTAGE SUBSYSTEM
    

    # set output offset voltage to a value
    def set_output_offset_voltage(self, channel: int, value: float):
        try:
            start_t = time.time()
            channel = str(channel)
            value = str(value)
            command = f":VOLT{channel}:OFFS {value}"
            self.write_instrument(command=command)
            query_val = self.get_output_offset_voltage(channel=channel)
            stop_t = time.time()
            response_t = (stop_t - start_t) * 1000
            log = self.logger._log_command(command=command, duration_ms= response_t, response=query_val)

            self.print_msg(instrument_name= self.instrument_name, parameter_name="output offset", 
                        value= float(value), query_val=query_val)

            #set_v = float(self.get_output_offset_voltage(channel=channel))

            return log
        except Exception as e:
            log = self.logger._log_command(command=command, duration_ms= response_t, response=self.query_instrument(":SYST:ERR?"))
            self.print_errors(f"Failed to set the value: {e}")
            return log
    
    def set_output_offset_min_max(self, channel: int, mode: str):
        channel = str(channel)
        try:
            if mode in ["MIN", "MAX"]:
                start_time = time.time()
                command = f":VOLT{str(channel)}:OFFS {str(mode)}"
                self.write_instrument(command=command)
                query_val = self.get_output_offset_voltage(channel=channel)
                stop_t = time.time()
                response_t = (stop_t - start_time) * 1000
                log = self.logger._log_command(command=command, duration_ms= response_t, response=query_val)
                self.print_msg(parameter_name= f"offset voltage of channel {channel} in volts", value= -0.02, query_val=query_val)
                return log

        except Exception as e:
            log = self.logger._log_command(command=command, duration_ms= response_t, response=self.query_instrument(":SYST:ERR?"))
            self.print_errors(error_message=str(e))
            return log

    # Set output high level to a custom value
    def set_output_high_level_custom(self, channel: int, value: float):
       
        try:
            channel = str(channel)
            value = str(value)
            start_time = time.time()
            command = f":VOLT{channel}:HIGH {value}"
            self.write_instrument(command=command)
            duration = (time.time() - start_time) * 1000
            response = float(self.get_output_high_level(channel).strip())
            log = self.logger._log_command(command=command, duration_ms= duration, response=response)
            self.print_msg(parameter_name=f"output high level of channel {channel}", value=value, query_val= response)
            return log
        except Exception as e:
                log = self.logger._log_command(command=command, duration_ms= duration, response=self.query_instrument(":SYST:ERR?"))
                self.print_errors(str(e))
                return log

    # Set output voltage high level to minimum or maximum
    def set_output_high_level_minmax(self, channel:int, mode: str):
        try:
            start_t = time.time()
            channel = str(channel)
            mode = str(mode)
            if mode in ['MIN', 'MAX']:
                command = f":VOLT:HIGH {mode}"
                self.write_instrument(command=command)
                query = self.get_output_high_level(channel=channel)
            end_t = time.time()
            response_t = (end_t - start_t) * 1000
            log = self.logger._log_command(command=command, duration_ms= response_t, response=query)
            self.print_msg(parameter_name="output high level", value= query, query_val=query)
            return log
        except Exception as e:
            log = self.logger._log_command(command=command, duration_ms= response_t, response=self.query_instrument(":SYST:ERR?"))
            self.print_errors(str(e))
            return log

    # Set output low level to a custom value
    def set_output_low_level_custom(self, channel: int, value: float):
       
        try:
            channel = str(channel)
            value = str(value)
            start_time = time.time()
            command = f":VOLT{channel}:LOW {value}"
            self.write_instrument(command=command)
            duration = (time.time() - start_time) * 1000
            response = float(self.get_output_high_level(channel).strip())
            log = self.logger._log_command(command=command, duration_ms= duration, response=response)
            self.print_msg(parameter_name=f"output low level of channel {channel}", value=value, query_val= response)
            return log
        except Exception as e:
                log = self.logger._log_command(command=command, duration_ms= duration, response=self.query_instrument(":SYST:ERR?"))
                self.print_errors(str(e))
                return log

    # Set output voltage low level to minimum or maximum
    def set_output_low_level_minmax(self, channel:int, mode: str):
        try:
            start_t = time.time()
            channel = str(channel)
            mode = str(mode)
            if mode in ['MIN', 'MAX']:
                command = f":VOLT:LOW {mode}"
                self.write_instrument(command=command)
                query = self.get_output_high_level(channel=channel)
            end_t = time.time()
            response_t = (end_t - start_t) * 1000
            log = self.logger._log_command(command=command, duration_ms= response_t, response=query)
            self.print_msg(parameter_name="output low level", value= query, query_val=query)
            return log
        except Exception as e:
            log = self.logger._log_command(command=command, duration_ms= response_t, response=self.query_instrument(":SYST:ERR?"))
            self.print_errors(str(e))
            return log

    # Set output termination voltage to a custom value
    def set_output_termination_custom(self, channel: int, value: float):
       
        try:
            channel = str(channel)
            value = str(value)
            start_time = time.time()
            command = f":VOLT{channel}:TERM {value}"
            self.write_instrument(command=command)
            duration = (time.time() - start_time) * 1000
            response = float(self.get_output_termination(channel).strip())
            log = self.logger._log_command(command=command, duration_ms= duration, response=response)
            self.print_msg(parameter_name=f"output termination voltage of channel {channel}", value=value, query_val= response)
            return log
        except Exception as e:
                log = self.logger._log_command(command=command, duration_ms= duration, response=self.query_instrument(":SYST:ERR?"))
                self.print_errors(str(e))
                return log

    # Set output voltage termination voltage to minimum or maximum
    def set_output_termination_minmax(self, channel:int, mode: str):
        try:
            start_t = time.time()
            channel = str(channel)
            mode = str(mode)
            if mode in ['MIN', 'MAX']:
                command = f":VOLT:TERM {mode}"
                self.write_instrument(command=command)
                query = self.get_output_termination(channel=channel)
            end_t = time.time()
            response_t = (end_t - start_t) * 1000
            log = self.logger._log_command(command=command, duration_ms= response_t, response=query)
            self.print_msg(parameter_name="output termination voltage", value= query, query_val=query)
            return log
        except Exception as e:
            log = self.logger._log_command(command=command, duration_ms= response_t, response=self.query_instrument(":SYST:ERR?"))
            self.print_errors(str(e))
            return log

    # Set output amplitude of a channel in volts to a custom value
    def set_output_voltage_custom(self, channel, value):
        try:
            start_t = time.time()
            channel = str(channel)
            value = str(value)

            command = f":VOLT{channel} {value}"
            self.write_instrument(command=command)
            end_t = time.time()
            response_t = (end_t - start_t) * 1000
            query_val = self.get_output_voltage(channel=channel)
            log = self.logger._log_command(command=command, duration_ms= response_t, response=query_val)
            self.print_msg(parameter_name=f"output amplitude of {channel} in volts", value=float(value), query_val=query_val)
            return log
        except Exception as e:
            log = self.logger._log_command(command=command, duration_ms= response_t, response=self.query_instrument(":SYST:ERR?"))
            self.print_errors(error_message=str(e))
            return log

        #return query_val
    # Set output amplitude of a channel to minimum or maximum
    def set_output_voltage_minmax(self, channel, mode: str):
        start_t = time.time()
        channel = str(channel)
        try:
            if mode in ['MIN', 'MAX']:
                start_t = time.time()
                command = f":VOLT{channel} {mode}"
                self.write_instrument(command=command)
                query_val = self.get_output_voltage(channel=channel)
                stop_t = time.time()
                response_t = (stop_t - start_t) * 1000
                self.print_msg(parameter_name=f"output amplitude of channel {channel} in volts", value=0.01, query_val=query_val)
                log = self.logger._log_command(command=command, duration_ms= response_t, response=query_val)
                return log
        except Exception as e:
            log = self.logger._log_command(command=command, duration_ms= response_t, response=self.query_instrument(":SYST:ERR?"))
            self.print_errors(error_message=str(e))
            return log
    
    # WRITE OUTPUT SUBSYSTEM 
    
    def set_output_state (self, channel, state: str):
        start_t = time.time()

        options = ['ON', 'OFF', 1, 0]

        if state in options:
            command = f":OUTP{channel} {state}"
            self.write_instrument(command=str(command))
            stop_t = time.time()
            response_t = (stop_t - start_t) * 1000
            log = self.logger._log_command(command=command, duration_ms= response_t, response=None)
            return log
        else:
            log = self.logger._log_command(command=command, duration_ms=response_t, response=self.query_instrument(":SYST:ERR?"))
            print ("Error, invalid option!!")
            return log


    ############### FILE HANDLE #####################
    def import_file(self, filename):
        try:
            start_t = time.time()
            command = f':TRAC1:IQIM 1,"{filename}",CSV,IONL,0'
            self.write_instrument(command=str(command))

            query = self.query_instrument(':SYST:ERR?')
            stop_t = time.time()
            response_t = (stop_t - start_t) * 1000
            log = self.logger._log_command(command=command, duration_ms= response_t, response=query)
            self.print_query_msg(str(query))
            return log
        except Exception as e:
            log = self.logger._log_command(command=command, duration_ms=response_t, response=self.query_instrument(":SYST:ERR?"))
            self.print_errors(error_message= str(e))
            return log



    ################### SEGMENT ######################

    # Query Segment
    def query_segment(self, channel:int):
        try:
            start_t = time.time()
            channel = str(channel)
            command = f':TRACE{channel}:CAT?'
            response = self.query_instrument(query=command)
            self.print_query_msg(response=response)
            stop_t = time.time()
            resposnse_t = (stop_t - start_t) * 1000
            self.logger._log_command(command=command, duration_ms= resposnse_t, response=response)
        except Exception as e:
            self.logger._log_command(command=command, duration_ms= resposnse_t, response= self.query_instrument(":SYST:ERR?"))
            self.print_errors(str(e))

    # Define Segment
    def define_segment(self, channel:int,segment_id: int, n_sample:float):
        try:
            start_t = time.time()
            channel = str(channel)
            n_sample = str(n_sample)
            segment_id = str(segment_id)
            command = f':TRAC1:DEF {channel},{segment_id},{n_sample},0'
            self.write_instrument(command=command)
            query = ':SYST:ERR?'
            response = self.query_instrument(query=query)
            end_t = time.time()
            response_t = (start_t - end_t) * 1000
            log = self.logger._log_command(command=command, duration_ms=response_t, response=response)
            self.print_query_msg(response=response)
            return log
        except Exception as e:
            log = self.logger._log_command(command=command, duration_ms=response_t, response=self.query_instrument(":SYST:ERR?"))
            self.print_errors(error_message=str(e))  
            return log

    # Delete a Segment
    def delete_segment(self, channel:int, id:int):
        try:
            start_t = time.time()
            channel = str(channel)
            id = str(id)
            command = f':TRACE{channel}:DEL {id}'  
            query = ':SYST:ERR?'
            self.write_instrument(command=command)
            response = self.query_instrument(query=query)
            end_t = time.time()
            response_t = (end_t - start_t) * 1000
            log = self.logger._log_command(command=command, duration_ms= response_t, response=response)
            self.print_query_msg(response=response)
            return log
        except Exception as e: 
            log = self.logger._log_command(command=command, duration_ms=response_t, response=self.query_instrument(":SYST:ERR?"))
            self.print_errors(str(e))
            return log
            
    ########### ABORT WAVE GENERATION #################

    def abort_wave_generation(self, channel:int): 
        try:
            start_t = time.time()
            channel = str(channel) 
            command = f':ABOR{channel}'
            query = ':SYST:ERR?'

            self.write_instrument(command=command)
            end_t = time.time()
            response_t = (end_t - start_t) * 1000
            response = self.query_instrument(query=query) 
            log = self.logger._log_command(command=command, duration_ms= response_t, response=response)
            self.print_query_msg(response=response)
            return log

        except Exception as e: 
            log = self.logger._log_command(command=command, duration_ms= response_t, response=self.query_instrument(":SYST:ERR?"))
            self.print_errors(str(e)) 
            return log
    
    ######### INITIATE SIGNAL GENERATION ON ALL CHANNELS ##################

    def initiate_signal(self, channel:int): 
        try:
            start_t = time.time()
            channel = str(channel)
            command = f':INIT:IMM{channel}'
            query = ':SYST:ERR?'
            self.write_instrument(command=command)
            response = self.query_instrument(query=query) 
            end_time = time.time()
            response_t = (end_time  - start_t) * 1000
            self.print_query_msg(response=response) 
            self.logger._log_command(command= command, duration_ms= response_t, response=response)
        except Exception as e: 
            self.logger._log_command(command=command, duration_ms= response_t, response=self.query_instrument(":SYST:ERR?"))
            self.print_errors(str(e)) 
       


if __name__ == "__main__":
    '''args = parse_args()
    instrument = args.instrument
    ip_address = args.IP

    print(f"Selected instrument: {instrument}\n", f"IP address {ip_address}")
    
    awg = AWG_Controller(instrument_name= instrument, ip_address= ip_address)
    #awg.connect()
    #awg.set_output_voltage_minmax(1, "MAX")
    awg.get_output_high_level(1)'''





