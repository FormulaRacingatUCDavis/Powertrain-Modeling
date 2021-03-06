classdef InternalResistance

   properties
      Vehicle
      Name              % Instance Name [str]
      Date              % Data Generated [yyyy-mm-dd_HH_MM]
      Notes             % Input & Output Summary [str]
      Type              % Which kind of battery was used
      
      Parameters        % What temperature
      
   end
   
   methods
      function obj = InternalResistance(Vehicle, Parameters, Type)
         
          if nargin == 3
            obj.Vehicle = Vehicle;
            obj.Date = datestr(now,'yyyy-mm-dd_HH_MM');
            obj.Type = char(Type);
            obj.Name = [Vehicle, '_IR_', obj.Type, '_', obj.Date];
            obj.Notes{1} = input('Please Note Primary Parameter Changes: \n', 's');
            obj.Parameters = Parameters;
            
          end
      end
   end
end