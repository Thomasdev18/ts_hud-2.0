import React, { useState } from "react";
import { Text, DEFAULT_THEME, Box } from '@mantine/core';
import { useNuiEvent } from "../hooks/useNuiEvent";
import { PiSeatbeltFill, PiEngineFill } from "react-icons/pi";
import useStyles from '../hooks/useStyles';
import '../index.css';

const Vehicle: React.FC = () => {
  const { classes } = useStyles();
  const theme = DEFAULT_THEME;
  const [speed, setSpeed] = useState<number>(0);
  const [gear, setGear] = useState<number>(0);
  const [speedType, setSpeedType] = useState<string>('KMT');
  const [seatbeltOn, setSeatbeltOn] = useState<boolean>(false);
  const [streetName1, setStreetName1] = useState<string>('OSLO');
  const [streetName2, setStreetName2] = useState<string>('FROGNER');
  const [heading, setHeading] = useState<string>('N');
  const [fuel, setFuel] = useState<number>(40);
  const [engineHealth, setEngineHealth] = useState<number>(100);
  const [nitrous, setNitrous] = useState<number>(50);
  const [isInVehicle, setIsInVehicle] = useState<boolean>(true);
  const [isHarnessOn, setHarnessOn] = useState<boolean>(false);

  useNuiEvent<any>('vehicle', (data) => {
    setSpeed(data.speed);
    setGear(data.gear);
    setSpeedType(data.speedType);
    setSeatbeltOn(data.seatbeltOn);
    setStreetName1(data.streetName1 || 'UNKNOWN');
    setStreetName2(data.streetName2 || 'UNKNOWN');
    setHeading(data.heading || 'N');
    setFuel(data.fuel || 100);
    setEngineHealth(data.engineHealth || 100);
    setNitrous(data.nitrous || 0);
    setIsInVehicle(data.isInVehicle);
    setHarnessOn(data.isHarnessOn);
  });

  return (
    <div className={classes.wrapperVehicle}>
      {isInVehicle && (
        <Box className={classes.minimapContainer}>
          <Box className={classes.minimap}>
            {/* Nitrous bar on top of the minimap container */}
            {nitrous > 0 && (
              <Box className={classes.horizontalBar} style={{ top: '-47px' }}>
                <Box className={classes.nitrousBar} style={{ width: `${nitrous}%` }} />
              </Box>
            )}

            {/* Fuel bar below nitrous bar */}
            <Box className={classes.horizontalBar} style={{ top: '-32px' }}>
              <Box className={classes.fuelBar} style={{ width: `${fuel}%` }} />
            </Box>

            {/* Heading in the top left */}
            <Text className={classes.heading}>{heading}</Text>

            {/* Street names in the top right */}
            <Box className={classes.streetNames}>
              <Text className={classes.streetName1}>{streetName1}</Text>
            </Box>

            {/* Speed on bottom left */}
            <Text className={classes.speed}>
              {speed.toString().padStart(3, '0')} {speedType.toUpperCase()}
            </Text>

            {/* Gear on bottom right */}
            <Text className={classes.gear}>{gear === 0 ? 'R' : gear}</Text>

            {/* Seatbelt and Engine icons above the speed */}
            <Box className={classes.iconGroup}>
              <PiSeatbeltFill
                className={seatbeltOn ? classes.seatbeltIconOn : classes.seatbeltIcon}
              />
              {engineHealth <= 30 && (
                <PiEngineFill className={classes.engineIcon} />
              )}
            </Box>
          </Box>
        </Box>
      )}
    </div>
  );
}

export default Vehicle;
