import React, { useState, useEffect } from "react";
import { Group, ThemeIcon, Box, Center, RingProgress, DEFAULT_THEME } from '@mantine/core';
import { TbLungs } from 'react-icons/tb';
import { FaHeart, FaWalkieTalkie, FaSkull, FaMicrophone, FaShield, FaBrain } from "react-icons/fa6";
import { FaMicrophoneSlash } from 'react-icons/fa';
import { MdLocalDrink, MdRestaurant } from "react-icons/md";
import HUDSettings from './HUDSettings';
import useStyles from '../hooks/useStyles';
import { useNuiEvent } from "../hooks/useNuiEvent";
import { fetchNui } from "../utils/fetchNui";

const Player: React.FC = () => {
    const { classes } = useStyles();
    const theme = DEFAULT_THEME;
    const [health, setHealth] = useState<number>(40);
    const [armor, setArmor] = useState<number>(50);
    const [thirst, setThirst] = useState<number>(50);
    const [hunger, setHunger] = useState<number>(50);
    const [oxygen, setOxygen] = useState<number>(50);
    const [stress, setStress] = useState<number>(50);
    const [talking, setTalking] = useState<any>(false);
    const [voice, setVoice] = useState<number>(0);
    const [colors, setColors] = useState<any>({
        voiceInactive: '#6c757d',
        voiceActive: '#ffffff',
        voiceRadio: '#1c7ed6',
        health: '#099268',
        armor: '#1098ad',
        oxygen: '#228be6',
        hunger: '#f08c00',
        thirst: '#1971c2',
        stress: '#ff6b6b',
    });
    const [position, setPosition] = useState<string>('left');
    const [hudType, setHudType] = useState<string>('minimal');
    const [vehicleType, setVehicleType] = useState<string>('default');
    const [opened, setOpened] = useState(false);

    useNuiEvent<any>('player', (data) => {
        setColors(data.colors);
        setHealth(data.health);
        setArmor(data.armor);
        setThirst(data.thirst);
        setHunger(data.hunger);
        setOxygen(data.oxygen);
        setStress(data.stress);
        setTalking(data.talking);
        setVoice(data.voice);
        setHudType(data.hudType);
        setPosition(data.hudPosition);
    });

    useNuiEvent('HUDSettings', (data: boolean) => {
        setOpened(data);
    });

    useNuiEvent<any>('player', (data) => {
        if (data.hudType) {
            setHudType(data.hudType);
        }
        if (data.hudPosition) {
            setPosition(data.hudPosition);
        }
    });

    const getPositionStyle = () => {
        switch (position) {
            case 'center':
                return { left: '50%', transform: 'translateX(-50%)' };
            case 'right':
                return { right: 10 };
            default:
                return { left: 10 };
        }
    };

    const renderRectangleProgress = (value: number, progressColor: string, icon: React.ReactNode) => {
        return (
            <Box
                sx={{
                    width: 40,
                    height: 40,
                    display: 'flex',
                    alignItems: 'center',
                    justifyContent: 'center',
                    backgroundColor: theme.colors.dark[5],
                    border: `2px solid ${theme.colors.dark[4]}`,
                    borderRadius: 10,
                    padding: '8px',
                    boxSizing: 'border-box',
                    position: 'relative',
                }}
            >
                <Box
                    sx={{
                        width: '100%',
                        height: '100%',
                        position: 'absolute',
                        bottom: 0,
                        backgroundColor: progressColor,
                        borderRadius: 8,
                        clipPath: `inset(${100 - value}% 0 0 0)`,
                    }}
                />
                <ThemeIcon 
                    sx={{ 
                        color: '#f1f3f5',
                        backgroundColor: "transparent",
                        zIndex: 1, 
                    }} 
                    radius="xl" 
                    size={30}
                >
                    {icon}
                </ThemeIcon>
            </Box>
        );
    };

    const renderCircleProgress = (value: number, progressColor: string, icon: React.ReactNode) => {
        return (
            <Box
                sx={{
                    width: 45,
                    height: 45,
                    display: 'flex',
                    alignItems: 'center',
                    justifyContent: 'center',
                    backgroundColor: theme.colors.dark[5],
                    border: `2px solid ${theme.colors.dark[4]}`,
                    borderRadius: '50%',
                    padding: '5px',
                    position: 'relative',
                }}
            >
                <RingProgress
                    sections={[{ value: value, color: progressColor }]}
                    thickness={2}
                    size={45}
                    roundCaps
                    sx={{ position: 'absolute'}}
                    label={
                        <Center>
                            <ThemeIcon 
                                sx={{ 
                                    color: '#f1f3f5',
                                    backgroundColor: "transparent",
                                    zIndex: 1, 
                                }} 
                                radius="xl" 
                                size={30}
                            >
                                {icon}
                            </ThemeIcon>
                        </Center>
                    }
                />
            </Box>
        );
    };

    const renderCompactProgress = (value: number, progressColor: string, icon: React.ReactNode) => {
        return (
            <Box
                sx={{
                    width: 42,
                    height: 50,
                    left: 4,
                    display: 'flex',
                    flexDirection: 'column',
                    alignItems: 'center',
                    justifyContent: 'space-between',
                    backgroundColor: theme.colors.dark[5],
                    borderRadius: 5,
                    padding: '4px',
                    boxSizing: 'border-box',
                    position: 'relative',
                    border: `1px solid ${theme.colors.dark[4]}`
                }}
            >
                {/* Icon Box */}
                <Box
                    sx={{
                        width: 25,
                        height: 25,
                        backgroundColor: theme.colors.dark[4],
                        borderRadius: '50%',
                        display: 'flex',
                        alignItems: 'center',
                        justifyContent: 'center',
                        marginBottom: '4px',
                    }}
                >
                    <ThemeIcon 
                        sx={{ 
                            color: '#f1f3f5',
                            backgroundColor: "transparent",
                            zIndex: 1, 
                        }} 
                        radius="xl" 
                        size={15}
                    >
                        {icon}
                    </ThemeIcon>
                </Box>
    
                {/* Progress Bar */}
                <Box
                    sx={{
                        width: '100%',
                        height: '8px',
                        backgroundColor: theme.colors.dark[4],
                        borderRadius: 3,
                        overflow: 'hidden',
                        position: 'relative',
                    }}
                >
                    <Box
                        sx={{
                            width: `${value}%`,
                            height: '100%',
                            backgroundColor: progressColor,
                            transition: 'width 0.3s ease',
                        }}
                    />
                </Box>
            </Box>
        );
    };

    const renderMinimalProgress = (value: number, progressColor: string, icon: React.ReactNode) => {
        return (
            <Box
                sx={{
                    width: 42,
                    height: 50,
                    left: 4,
                    display: 'flex',
                    flexDirection: 'column',
                    alignItems: 'center',
                    justifyContent: 'space-between',
                    padding: '9px',
                    boxSizing: 'border-box',
                    position: 'relative',
                }}
            >
                {/* Icon */}
                <ThemeIcon 
                    sx={{ 
                        color: '#f1f3f5',
                        backgroundColor: "transparent",
                        zIndex: 1, 
                    }} 
                    radius="xl" 
                    size={20}
                >
                    {icon}
                </ThemeIcon>
    
                {/* Progress Bar */}
                <Box
                    sx={{
                        width: '30px',
                        height: '6px',
                        backgroundColor: theme.colors.dark[4],
                        borderRadius: 3,
                        overflow: 'hidden',
                        position: 'relative',
                    }}
                >
                    <Box
                        sx={{
                            width: `${value}%`,
                            height: '100%',
                            backgroundColor: progressColor,
                            transition: 'width 0.3s ease',
                        }}
                    />
                </Box>
            </Box>
        );
    };

    return (
        <div className={classes.wrapperPlayer}>
            <Group spacing={4} style={{ position: 'absolute', bottom: 5, ...getPositionStyle() }}>
                {hudType === 'rectangle' && renderRectangleProgress(voice === 1.5 ? 25 : voice === 3.0 ? 50 : 100, talking === 'radio' ? colors.voiceRadio : talking === 'voice' ? colors.voiceActive : colors.voiceInactive, !talking ? <FaMicrophoneSlash size={20} /> : talking === 'voice' ? <FaMicrophone size={20} /> : <FaWalkieTalkie size={20} />)}
                {hudType === 'circle' && renderCircleProgress(voice === 1.5 ? 25 : voice === 3.0 ? 50 : 100, talking === 'radio' ? colors.voiceRadio : talking === 'voice' ? colors.voiceActive : colors.voiceInactive, !talking ? <FaMicrophoneSlash size={18} /> : talking === 'voice' ? <FaMicrophone size={18} /> : <FaWalkieTalkie size={18} />)}
                {hudType === 'compact' && renderCompactProgress(voice === 1.5 ? 25 : voice === 3.0 ? 50 : 100, talking === 'radio' ? colors.voiceRadio : talking === 'voice' ? colors.voiceActive : colors.voiceInactive, !talking ? <FaMicrophoneSlash size={16} /> : talking === 'voice' ? <FaMicrophone size={16} /> : <FaWalkieTalkie size={16} />)}
                {hudType === 'minimal' && renderMinimalProgress(voice === 1.5 ? 25 : voice === 3.0 ? 50 : 100, talking === 'radio' ? colors.voiceRadio : talking === 'voice' ? colors.voiceActive : colors.voiceInactive, !talking ? <FaMicrophoneSlash size={16} /> : talking === 'voice' ? <FaMicrophone size={16} /> : <FaWalkieTalkie size={16} />)}

                {hudType === 'rectangle' && renderRectangleProgress(health, health <= 0 ? 'red' : colors.health, health > 0 ? <FaHeart size={20} /> : <FaSkull size={20} />)}
                {hudType === 'circle' && renderCircleProgress(health, health <= 0 ? 'red' : colors.health, health > 0 ? <FaHeart size={18} /> : <FaSkull size={18} />)}
                {hudType === 'compact' && renderCompactProgress(health, health <= 0 ? 'red' : colors.health, health > 0 ? <FaHeart size={16} /> : <FaSkull size={16} />)}
                {hudType === 'minimal' && renderMinimalProgress(health, health <= 0 ? 'red' : colors.health, health > 0 ? <FaHeart size={16} /> : <FaSkull size={16} />)}

                {armor > 0 && hudType === 'rectangle' && renderRectangleProgress(armor, colors.armor, <FaShield size={20} />)}
                {armor > 0 && hudType === 'circle' && renderCircleProgress(armor, colors.armor, <FaShield size={18} />)}
                {armor > 0 && hudType === 'compact' && renderCompactProgress(armor, colors.armor, <FaShield size={16} />)}
                {armor > 0 && hudType === 'minimal' && renderMinimalProgress(armor, colors.armor, <FaShield size={16} />)}

                {thirst < 100 && hudType === 'rectangle' && renderRectangleProgress(thirst, thirst <= 20 ? 'red' : colors.thirst, <MdLocalDrink size={20} />)}
                {thirst < 100 && hudType === 'circle' && renderCircleProgress(thirst, thirst <= 20 ? 'red' : colors.thirst, <MdLocalDrink size={18} />)}
                {thirst < 100 && hudType === 'compact' && renderCompactProgress(thirst, thirst <= 20 ? 'red' : colors.thirst, <MdLocalDrink size={16} />)}
                {thirst < 100 && hudType === 'minimal' && renderMinimalProgress(thirst, thirst <= 20 ? 'red' : colors.thirst, <MdLocalDrink size={16} />)}

                {hunger < 100 && hudType === 'rectangle' && renderRectangleProgress(hunger, hunger <= 20 ? 'red' : colors.hunger, <MdRestaurant size={20} />)}
                {hunger < 100 && hudType === 'circle' && renderCircleProgress(hunger, hunger <= 20 ? 'red' : colors.hunger, <MdRestaurant size={18} />)}
                {hunger < 100 && hudType === 'compact' && renderCompactProgress(hunger, hunger <= 20 ? 'red' : colors.hunger, <MdRestaurant size={16} />)}
                {hunger < 100 && hudType === 'minimal' && renderMinimalProgress(hunger, hunger <= 20 ? 'red' : colors.hunger, <MdRestaurant size={16} />)}

                {oxygen < 100 && hudType === 'rectangle' && renderRectangleProgress(oxygen, oxygen <= 20 ? 'red' : colors.oxygen, <TbLungs size={20} />)}
                {oxygen < 100 && hudType === 'circle' && renderCircleProgress(oxygen, oxygen <= 20 ? 'red' : colors.oxygen, <TbLungs size={18} />)}
                {oxygen < 100 && hudType === 'compact' && renderCompactProgress(oxygen, oxygen <= 20 ? 'red' : colors.oxygen, <TbLungs size={16} />)}
                {oxygen < 100 && hudType === 'minimal' && renderMinimalProgress(oxygen, oxygen <= 20 ? 'red' : colors.oxygen, <TbLungs size={16} />)}

                {stress > 0 && hudType === 'rectangle' && renderRectangleProgress(stress, colors.stress, <FaBrain size={20} />)}
                {stress > 0 && hudType === 'circle' && renderCircleProgress(stress, colors.stress, <FaBrain size={18} />)}
                {stress > 0 && hudType === 'compact' && renderCompactProgress(stress, colors.stress, <FaBrain size={16} />)}
                {stress > 0 && hudType === 'minimal' && renderMinimalProgress(stress, colors.stress, <FaBrain size={16} />)}
            </Group>

            <HUDSettings 
                opened={opened} 
                onClose={() => setOpened(false)} 
                colors={colors}
                setColors={setColors} 
                position={position}
                setPosition={setPosition}
                hudType={hudType}
                setHudType={setHudType}
                vehicleType={vehicleType}
                setVehicleType={setVehicleType}
            />
        </div>
    );
}

export default Player;
