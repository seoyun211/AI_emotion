import React, { createContext, useState, useContext, useEffect } from 'react';
import { guardianAPI } from '../services/api';
import AsyncStorage from '@react-native-async-storage/async-storage';

const AuthContext = createContext();

export const useAuth = () => {
  const context = useContext(AuthContext);
  if (!context) {
    throw new Error('useAuth must be used within an AuthProvider');
  }
  return context;
};

export const AuthProvider = ({ children }) => {
  const [user, setUser] = useState(null);
  const [token, setToken] = useState(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    // 앱 시작 시 저장된 토큰 확인
    loadStoredToken();
  }, []);

  const loadStoredToken = async () => {
    try {
      const storedToken = await AsyncStorage.getItem('guardian_token');
      if (storedToken) {
        setToken(storedToken);
        // 토큰 유효성 확인
        await fetchUserInfo(storedToken);
      }
    } catch (error) {
      console.error('Token load failed:', error);
    } finally {
      setLoading(false);
    }
  };

  const fetchUserInfo = async (userToken) => {
    try {
      const userInfo = await guardianAPI.getMyInfo(userToken);
      setUser(userInfo);
    } catch (error) {
      console.error('User info fetch failed:', error);
      await logout();
    }
  };

  const login = async (phone, password) => {
    try {
      const result = await guardianAPI.login(phone, password);
      
      if (result.access_token) {
        await AsyncStorage.setItem('guardian_token', result.access_token);
        setToken(result.access_token);
        await fetchUserInfo(result.access_token);
        return { success: true };
      }
    } catch (error) {
      console.error('Login failed:', error);
      return { success: false, error: '로그인 실패' };
    }
  };

  const register = async (guardianData) => {
    try {
      const result = await guardianAPI.register(guardianData);
      return { success: true, data: result };
    } catch (error) {
      console.error('Registration failed:', error);
      return { success: false, error: '회원가입 실패' };
    }
  };

  const logout = async () => {
    try {
      await AsyncStorage.removeItem('guardian_token');
      setToken(null);
      setUser(null);
    } catch (error) {
      console.error('Logout failed:', error);
    }
  };

  const value = {
    user,
    token,
    login,
    register,
    logout,
    loading,
    isAuthenticated: !!token,
  };

  return (
    <AuthContext.Provider value={value}>
      {children}
    </AuthContext.Provider>
  );
};