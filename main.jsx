import React, { Component } from 'react';
import { AppRegistry, Text, View, StyleSheet, TextInput, TouchableOpacity, ScrollView, Switch, Alert, Dimensions } from 'react-native';
import AsyncStorage from '@react-native-async-storage/async-storage';
import Constants from 'expo-constants';

let deviceHeight = Dimensions.get('window').height;
let deviceWidth = Dimensions.get('window').width;

export default class App extends Component {
  constructor(props) {
    super(props);
    this.state = {
      assignments: [],
      newAssignment: '',
      dueDate: '',
      priority: 'Medium',
      darkMode: false,
      editIndex: null,
    };
  }

  componentDidMount() {
    this.loadAssignments();
    this.loadDarkMode();
  }

  saveAssignments = async () => {
    try {
      await AsyncStorage.setItem('assignments', JSON.stringify(this.state.assignments));
    } catch (error) {
      console.log(error);
    }
  };

  loadAssignments = async () => {
    try {
      const assignments = await AsyncStorage.getItem('assignments');
      if (assignments) {
        this.setState({ assignments: JSON.parse(assignments) });
      }
    } catch (error) {
      console.log(error);
    }
  };

  saveDarkMode = async () => {
    try {
      await AsyncStorage.setItem('darkMode', JSON.stringify(this.state.darkMode));
    } catch (error) {
      console.log(error);
    }
  };

  loadDarkMode = async () => {
    try {
      const darkMode = await AsyncStorage.getItem('darkMode');
      if (darkMode !== null) {
        this.setState({ darkMode: JSON.parse(darkMode) });
      }
    } catch (error) {
      console.log(error);
    }
  };

  handleAssignmentChange = (text) => {
    this.setState({ newAssignment: text });
  };

  handleDueDateChange = (text) => {
    this.setState({ dueDate: text });
  };

  handlePriorityChange = (text) => {
    this.setState({ priority: text });
  };

  addOrEditAssignment = () => {
    if (this.state.newAssignment.trim() !== '' && this.state.dueDate.trim() !== '') {
      let updatedAssignments = [...this.state.assignments];
      if (this.state.editIndex !== null) {
        updatedAssignments[this.state.editIndex] = {
          title: this.state.newAssignment,
          dueDate: this.state.dueDate,
          priority: this.state.priority,
          completed: false,
        };
      } else {
        updatedAssignments.push({
          title: this.state.newAssignment,
          dueDate: this.state.dueDate,
          priority: this.state.priority,
          completed: false,
        });
      }
      updatedAssignments.sort((a, b) => new Date(a.dueDate) - new Date(b.dueDate));
      this.setState(
        { assignments: updatedAssignments, newAssignment: '', dueDate: '', priority: 'Medium', editIndex: null },
        this.saveAssignments
      );
    }
  };

  editAssignment = (index) => {
    const assignment = this.state.assignments[index];
    this.setState({ newAssignment: assignment.title, dueDate: assignment.dueDate, priority: assignment.priority, editIndex: index });
  };

  deleteAssignment = (index) => {
    const updatedAssignments = this.state.assignments.filter((_, i) => i !== index);
    this.setState({ assignments: updatedAssignments }, this.saveAssignments);
  };

  toggleDarkMode = () => {
    this.setState({ darkMode: !this.state.darkMode }, this.saveDarkMode);
  };

  generateCalendar = () => {
    const today = new Date();
    const year = today.getFullYear();
    const month = today.getMonth();

    const firstDay = new Date(year, month, 1).getDay();
    const daysInMonth = new Date(year, month + 1, 0).getDate();

    const calendar = [];
    let week = [];

    for (let i = 0; i < firstDay; i++) {
      week.push(null); // empty cells
    }

    for (let day = 1; day <= daysInMonth; day++) {
      week.push(day);
      if (week.length === 7) {
        calendar.push(week);
        week = [];
      }
    }

    if (week.length) {
      while (week.length < 7) {
        week.push(null);
      }
      calendar.push(week);
    }

    return calendar;
  };

  render() {
    return (
      <ScrollView style={[styles.container, this.state.darkMode && styles.darkContainer]} contentContainerStyle={{ paddingBottom: 100 }}>
        <Text style={[styles.header, this.state.darkMode && styles.darkText]}>Student Planner</Text>
        <Switch value={this.state.darkMode} onValueChange={this.toggleDarkMode} />

        <TextInput
          style={[styles.input, this.state.darkMode && styles.darkInput]}
          placeholder="Enter assignment title"
          placeholderTextColor="#aaa"
          value={this.state.newAssignment}
          onChangeText={this.handleAssignmentChange}
        />

        <TextInput
          style={[styles.input, this.state.darkMode && styles.darkInput]}
          placeholder="Enter due date (YYYY-MM-DD)"
          placeholderTextColor="#aaa"
          value={this.state.dueDate}
          onChangeText={this.handleDueDateChange}
        />

        <Text style={[styles.sectionTitle, this.state.darkMode && styles.darkText]}>
          Select Due Date (Current Month)
        </Text>

        <View style={styles.calendarContainer}>
          {this.generateCalendar().map((week, rowIndex) => (
            <View key={rowIndex} style={styles.calendarRow}>
              {week.map((day, colIndex) => (
                <TouchableOpacity
                  key={colIndex}
                  style={[
  styles.calendarCell,
  day && this.state.dueDate.endsWith(`-${day.toString().padStart(2, '0')}`) && styles.selectedDay,
]}

                  onPress={() => {
                    if (day) {
                      const today = new Date();
                      const month = today.getMonth() + 1;
                      const dateStr = `${today.getFullYear()}-${month.toString().padStart(2, '0')}-${day
                        .toString()
                        .padStart(2, '0')}`;
                      this.setState({ dueDate: dateStr });
                    }
                  }}
                >
                  <Text style={[styles.calendarText, this.state.darkMode && styles.darkText]}>
                    {day ? day : ''}
                  </Text>
                </TouchableOpacity>
              ))}
            </View>
          ))}
        </View>

        <TouchableOpacity style={styles.button} onPress={this.addOrEditAssignment}>
          <Text style={styles.buttonText}>{this.state.editIndex !== null ? 'Update Assignment' : 'Add Assignment'}</Text>
        </TouchableOpacity>

        <ScrollView style={styles.listContainer}>
          {this.state.assignments.map((assignment, index) => (
            <View key={index} style={styles.assignmentItem}>
              <Text style={[styles.assignmentTitle, assignment.completed && styles.completed, this.state.darkMode && styles.darkText]}>
                {assignment.title} ({assignment.priority})
              </Text>
              <Text style={[styles.assignmentDueDate, this.state.darkMode && styles.darkText]}>Due: {assignment.dueDate}</Text>

              <TouchableOpacity onPress={() => this.editAssignment(index)}>
                <Text style={styles.editButton}>Edit</Text>
              </TouchableOpacity>
              <TouchableOpacity onPress={() => this.deleteAssignment(index)}>
                <Text style={styles.deleteButton}>Delete</Text>
              </TouchableOpacity>
            </View>
          ))}
        </ScrollView>
      </ScrollView>
    );
  }
}

const styles = StyleSheet.create({
  container: { 
    height: deviceHeight, 
    width: deviceWidth, 
    padding: 10, 
    backgroundColor: '#f5f5f5' 
      
  },
  
  darkContainer: {
      backgroundColor: '#333' 
      
  },
  
  header: { 
  fontSize: 18, 
  fontWeight: 'bold', 
  textAlign: 'center', 
  marginBottom: 10 
      
  },
  
  darkText: { 
      color: '#fff' 
      
  },
  
  input: {
    height: 40, 
    borderColor: '#ccc', 
    borderWidth: 1, 
    borderRadius: 5,
    paddingHorizontal: 10, 
    marginBottom: 10, 
    backgroundColor: '#fff'
  },
  
  darkInput: { 
      backgroundColor: '#666', 
      color: '#fff' 
      
  },
  
  button: { 
      backgroundColor: '#007bff', 
      padding: 10, 
      borderRadius: 5, 
      alignItems: 'center' 
      
  },
  
  buttonText: { 
      color: 'white', 
      fontWeight: 'bold' 
      
  },
  
  listContainer: { 
      marginTop: 10 
      
  },
  
  assignmentItem: {
    padding: 10, 
    backgroundColor: '#fff', 
    marginBottom: 5, 
    borderRadius: 5,
    flexDirection: 'row', 
    justifyContent: 'space-between', 
    alignItems: 'center'
  },
  
  assignmentTitle: { 
      fontSize: 16, 
      flex: 1
  },
  
  completed: { 
      textDecorationLine: 'line-through', 
      backgroundColor: '#d4edda' 
      
  },
  
  assignmentDueDate: { 
      fontSize: 14, 
      color: '#888' 
      
  },
  
  deleteButton: { 
      color: 'red', 
      fontWeight: 'bold' 
      
  },

  sectionTitle: { 
      fontSize: 18, 
      fontWeight: 'bold', 
      marginTop: 15, 
      marginBottom: 5 
      
  },
  
  calendarContainer: {
    marginBottom: 10, 
    padding: 5, 
    borderRadius: 5, 
    backgroundColor: '#eaeaea'
  },
  
  calendarRow: { 
      flexDirection: 'row', 
      justifyContent: 'space-around', 
      marginVertical: 1
      
  },
  
  calendarCell: {
    width: 20, 
    height: 20, 
    justifyContent: 'center', 
    alignItems: 'center',
    backgroundColor: '#fff', 
    borderRadius: 2,
  },
  
  selectedDay: { 
      backgroundColor: '#007bff' 
      
  },
  
  calendarText: { 
      color: '#000', 
      fontWeight: 'bold' 
  },
});